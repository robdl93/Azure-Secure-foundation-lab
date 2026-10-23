# ============================================================
# MONITORING.TF
# ============================================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${local.name_prefix}-${local.unique_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Diagnostica NSG subnet privata
/* resource "azurerm_monitor_diagnostic_setting" "private_nsg" {
  name                       = "diag-nsg-private"
  target_resource_id         = azurerm_network_security_group.private_nsg.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

# Diagnostica VNet
resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name                       = "diag-vnet"
  target_resource_id         = azurerm_virtual_network.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "VMProtectionAlerts"
  }
}*/

# Diagnostica Bastion (traccia chi si connette)
resource "azurerm_monitor_diagnostic_setting" "bastion" {
  name                       = "diag-bastion"
  target_resource_id         = azurerm_bastion_host.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "BastionAuditLogs"
  }
}