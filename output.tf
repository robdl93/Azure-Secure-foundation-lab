# ============================================================
# OUTPUTS.TF
# ============================================================

output "resource_group_name" {
  description = "Nome del Resource Group creato"
  value       = azurerm_resource_group.main.name
}

output "vnet_name" {
  description = "Nome della VNet"
  value       = azurerm_virtual_network.main.name
}

output "bastion_public_ip" {
  description = "IP pubblico di Azure Bastion (unico punto di ingresso)"
  value       = azurerm_public_ip.bastion_pip.ip_address
}

output "vm_private_ip" {
  description = "IP privato della VM (non raggiungibile da internet)"
  value       = azurerm_network_interface.vm_nic.private_ip_address
}

output "vm_name" {
  description = "Nome della Virtual Machine"
  value       = azurerm_linux_virtual_machine.web.name
}

output "log_analytics_workspace_id" {
  description = "ID del Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "security_summary" {
  description = "Riepilogo sicurezza"
  value = <<-EOT
    ╔══════════════════════════════════════════════════════════╗
    ║         SECURE AZURE FOUNDATION - DEPLOYED              ║
    ╠══════════════════════════════════════════════════════════╣
    ║ ✅ VM deployata SENZA IP pubblico                       ║
    ║ ✅ Accesso SSH solo tramite Azure Bastion               ║
    ║ ✅ NSG applicati su tutte le subnet                     ║
    ║ ✅ Azure Policy attive                                  ║
    ║ ✅ Monitoring centralizzato su Log Analytics            ║
    ║ ✅ Bastion limitato al tuo IP pubblico                  ║
    ╚══════════════════════════════════════════════════════════╝
  EOT
}