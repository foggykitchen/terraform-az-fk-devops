output "project_id" {
  description = "Azure DevOps project ID."
  value       = azuredevops_project.this.id
}

output "project_name" {
  description = "Azure DevOps project name."
  value       = azuredevops_project.this.name
}

output "service_connection_id" {
  description = "ARM service connection ID, ready after federated trust creation."
  value       = azuredevops_serviceendpoint_azurerm.this.id
  depends_on  = [azuread_application_federated_identity_credential.this]
}

output "service_connection_name" {
  description = "ARM service connection name."
  value       = azuredevops_serviceendpoint_azurerm.this.service_endpoint_name
}

output "application_id" {
  description = "Entra application resource ID."
  value       = azuread_application.this.id
}

output "client_id" {
  description = "Entra application client ID used by the service connection."
  value       = azuread_application.this.client_id
}

output "principal_id" {
  description = "Entra service principal object ID for external RBAC composition."
  value       = azuread_service_principal.this.object_id
}

output "tenant_id" {
  description = "Entra tenant ID used by the AzureAD provider."
  value       = data.azuread_client_config.current.tenant_id
}

output "workload_identity_federation_issuer" {
  description = "Exact OIDC issuer returned by Azure DevOps."
  value       = azuredevops_serviceendpoint_azurerm.this.workload_identity_federation_issuer
}

output "workload_identity_federation_subject" {
  description = "Exact OIDC subject returned by Azure DevOps."
  value       = azuredevops_serviceendpoint_azurerm.this.workload_identity_federation_subject
}

output "federated_identity_credential_id" {
  description = "Entra federated identity credential resource ID."
  value       = azuread_application_federated_identity_credential.this.id
}

output "variable_group_ids" {
  description = "Variable group IDs keyed by logical name."
  value       = { for key, group in azuredevops_variable_group.this : key => group.id }
}
