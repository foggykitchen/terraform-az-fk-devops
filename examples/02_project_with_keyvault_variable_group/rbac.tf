module "pipeline_access" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-rbac.git?ref=47dda4c1f7b851941695ced6c5b48cc314ed3883"

  scope                = var.rbac_scope
  principal_id         = module.devops.principal_id
  role_definition_name = var.role_definition_name
}
