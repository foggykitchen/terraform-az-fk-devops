module "devops" {
  source = "../.."

  project_name = var.project_name
  service_connection = {
    name              = "fk-azure-oidc"
    subscription_id   = var.subscription_id
    subscription_name = var.subscription_name
  }

  variable_groups = var.link_variable_group ? {
    vault = {
      name         = "fk-key-vault-secrets"
      key_vault    = { name = module.key_vault.key_vault_name }
      secret_names = var.secret_names
    }
  } : {}
}
