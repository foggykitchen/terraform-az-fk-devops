resource "azuredevops_serviceendpoint_github" "this" {
  for_each = var.github_service_connections

  project_id            = azuredevops_project.this.id
  service_endpoint_name = each.value.name
  description           = each.value.description

  auth_personal {
    personal_access_token = lookup(var.github_service_connection_tokens, each.key, null)
  }
}
