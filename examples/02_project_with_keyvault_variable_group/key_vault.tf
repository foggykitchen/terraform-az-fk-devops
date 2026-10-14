data "azurerm_client_config" "current" {}

module "key_vault" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-key-vault.git?ref=e34d629e4b475086f50aad34011eb6ace030b7f3"

  key_vault_name                = var.key_vault_name
  resource_group_name           = azurerm_resource_group.foggykitchen_rg.name
  location                      = var.location
  tenant_id                     = var.tenant_id
  rbac_authorization_enabled    = false
  public_network_access_enabled = true
  access_policies = [{
    object_id          = module.devops.principal_id
    secret_permissions = ["Get", "List"]
    }, {
    object_id          = data.azurerm_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set"]
  }]
}
