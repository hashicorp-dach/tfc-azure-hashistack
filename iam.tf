resource "azurerm_user_assigned_identity" "vault" {

  location            = azurerm_resource_group.hashistack_resource_group.location
  name                = "hashistack-vault-1"
  resource_group_name = azurerm_resource_group.hashistack_resource_group.name
}

resource "azurerm_key_vault_access_policy" "vault_msi" {

  key_vault_id = azurerm_key_vault.hashistack_key_vault.id
  object_id    = azurerm_user_assigned_identity.vault.principal_id
  tenant_id    = data.azurerm_client_config.current.tenant_id

  key_permissions = [
    "Get",
    "UnwrapKey",
    "WrapKey",
  ]

  secret_permissions = [
    "Get",
  ]
}

resource "azurerm_role_definition" "vault" {

  name  = "hashistack-vault-server-1"
  scope = azurerm_resource_group.hashistack_resource_group.id

  assignable_scopes = [
    azurerm_resource_group.hashistack_resource_group.id
  ]

  permissions {
    actions = [
      "Microsoft.Network/networkInterfaces/*",
    ]
  }
}

resource "azurerm_role_assignment" "vault" {
  principal_id       = azurerm_user_assigned_identity.vault.principal_id
  role_definition_id = azurerm_role_definition.vault.role_definition_resource_id
  scope              = azurerm_resource_group.hashistack_resource_group.id
}
