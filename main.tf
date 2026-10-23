# ============================================================
# MAIN.TF
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Suffisso random per nomi unici a livello globale
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  name_prefix   = "${var.project_name}-${var.environment}"
  unique_suffix = random_string.suffix.result
}

# ============================================================
# RESOURCE GROUP
# ============================================================
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}-${local.unique_suffix}"
  location = var.location
  tags     = var.tags
}

# ============================================================
# VIRTUAL NETWORK
# ============================================================
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.name_prefix}-${local.unique_suffix}"
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Subnet Bastion (il nome DEVE essere "AzureBastionSubnet")
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.bastion_subnet_cidr]
}

# Subnet privata per la VM
resource "azurerm_subnet" "private" {
  name                 = "snet-private-${local.unique_suffix}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_subnet_cidr]
}

# ============================================================
# NETWORK SECURITY GROUPS (NSG)
# ============================================================

# NSG per Bastion
resource "azurerm_network_security_group" "bastion_nsg" {
  name                = "nsg-bastion-${local.unique_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  security_rule {
    name                       = "AllowHTTPSInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.allowed_ip_for_bastion
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowGatewayManagerInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAzureCloudOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  security_rule {
    name                       = "AllowVNetOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }
}

# NSG per la subnet privata
resource "azurerm_network_security_group" "private_nsg" {
  name                = "nsg-private-${local.unique_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  # SSH solo dalla subnet Bastion
  security_rule {
    name                       = "AllowSSHFromBastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.bastion_subnet_cidr
    destination_address_prefix = "*"
  }

  # Nega tutto il resto in ingresso
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associa NSG alle subnet
resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}

# ============================================================
# VIRTUAL MACHINE (senza IP pubblico)
# ============================================================

resource "azurerm_network_interface" "vm_nic" {
  name                = "nic-vm-${local.unique_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
    # NESSUN public_ip_address_id → VM non raggiungibile da internet
  }
}

resource "azurerm_linux_virtual_machine" "web" {
  #disable_password_authentication = false
  name                = "vm-web-${local.unique_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.vm_admin_username
  #admin_password     = var.vm_admin_password
  tags                = var.tags
  
  admin_ssh_key {
    username = var.vm_admin_username
	public_key = file("~/.ssh/id_rsa.pub")
	}

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# ============================================================
# AZURE BASTION HOST
# ============================================================

resource "azurerm_public_ip" "bastion_pip" {
  name                = "pip-bastion-${local.unique_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "main" {
  name                = "bas-${local.unique_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}