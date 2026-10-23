# ============================================================
# VARIABLES.TF
# ============================================================

variable "project_name" {
  description = "Nome del progetto, usato come prefisso per tutte le risorse"
  type        = string
  default     = "securelab"
}

variable "environment" {
  description = "Ambiente (dev, test, prod)"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure Region dove deployare le risorse"
  type        = string
  default     = "italynorth"
}

variable "vnet_address_space" {
  description = "Address space della VNet principale"
  type        = string
  default     = "10.0.0.0/16"
}

variable "bastion_subnet_cidr" {
  description = "CIDR per la subnet AzureBastionSubnet (deve essere /26 o più grande)"
  type        = string
  default     = "10.0.1.0/26"
}

variable "private_subnet_cidr" {
  description = "CIDR per la subnet privata dove risiede la VM"
  type        = string
  default     = "10.0.2.0/24"
}

variable "vm_size" {
  description = "Dimensione della Virtual Machine"
  type        = string
  default     = "Standard_D2als_v7"
}

variable "vm_admin_username" {
  description = "Username amministratore della VM Linux"
  type        = string
  default     = "azureadmin"
}

variable "vm_admin_password" {
  description = "Password amministratore della VM"
  type        = string
  sensitive   = true
}

variable "allowed_ip_for_bastion" {
  description = "Il TUO IP pubblico da cui puoi accedere a Bastion"
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  description = "Tag applicati a tutte le risorse"
  type        = map(string)
  default = {
    project     = "secure-foundation-lab"
    environment = "production"
    owner       = "cloud-engineering"
    purpose     = "microsoft-interview-project"
  }
}