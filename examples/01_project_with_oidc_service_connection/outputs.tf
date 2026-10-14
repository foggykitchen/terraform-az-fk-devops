output "project_id" {
  description = "Azure DevOps project ID."
  value       = module.devops.project_id
}

output "service_connection_id" {
  description = "Passwordless ARM service connection ID."
  value       = module.devops.service_connection_id
  depends_on  = [module.pipeline_access]
}

output "principal_id" {
  description = "Service principal object ID."
  value       = module.devops.principal_id
}

output "service_connection_name" {
  description = "ARM service connection name for the separately managed pipeline."
  value       = module.devops.service_connection_name
}

output "workload_identity_federation_issuer" {
  description = "Exact issuer returned by Azure DevOps."
  value       = module.devops.workload_identity_federation_issuer
}

output "workload_identity_federation_subject" {
  description = "Exact subject returned by Azure DevOps."
  value       = module.devops.workload_identity_federation_subject
}

output "resource_group_id" {
  description = "Resource Group created as the example RBAC scope."
  value       = azurerm_resource_group.foggykitchen_rg.id
}
