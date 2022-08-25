data "azurerm_client_config" "current" {
}

resource "azurerm_key_vault" "hashistack_key_vault" {
  name                        = "hashistack-key-vault"
  location                    = azurerm_resource_group.hashistack_resource_group.location
  resource_group_name         = azurerm_resource_group.hashistack_resource_group.name
  enabled_for_deployment = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get","List","Create","Delete","Update"
    ]
  }
}

resource "azurerm_key_vault_key" "hashistack_kms_key" {
  count = var.vault_enabled ? 1 : 0
  name         = "vault-autounseal-key"
  key_vault_id = azurerm_key_vault.hashistack_key_vault.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "unwrapKey",
    "wrapKey"
  ]
}