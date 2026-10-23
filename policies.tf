# ============================================================
# POLICIES.TF
# ============================================================

# Policy: ogni subnet DEVE avere un NSG
resource "azurerm_resource_group_policy_assignment" "require_nsg" {
  name                 = "require-nsg-${local.unique_suffix}"
  resource_group_id    = azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e71308d3-144b-4262-b144-efdc3cc90517"
  display_name         = "Require NSG on Subnets"
  description          = "Enforce that every subnet has a Network Security Group associated"
  parameters           = jsonencode({})
}

# Policy: limita le region utilizzabili
resource "azurerm_resource_group_policy_assignment" "restrict_locations" {
  name                 = "restrict-locations-${local.unique_suffix}"
  resource_group_id    = azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  display_name         = "Allowed Locations"
  description          = "Restrict resource deployment to Italy North only"

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = ["italynorth", "westeurope"]
    }
  })
}

# Policy: audit VM senza disk encryption
resource "azurerm_resource_group_policy_assignment" "audit_disk_encryption" {
  name                 = "audit-disk-encryption-${local.unique_suffix}"
  resource_group_id    = azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/06a78e20-9358-41c9-923c-fb736d382a4d"
  display_name         = "Audit VMs without Disk Encryption"
  description          = "Audit virtual machines that do not have disk encryption enabled"
}