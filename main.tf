data "azuread_client_config" "current" {}

locals {
  effective_owners = setunion(
    var.owners,
    var.include_current_principal_as_owner ? toset([data.azuread_client_config.current.object_id]) : toset([])
  )
}

resource "azuredevops_project" "this" {
  name               = var.project_name
  description        = var.project_description
  visibility         = var.project_visibility
  version_control    = "Git"
  work_item_template = var.work_item_template
}

resource "azuread_application" "this" {
  display_name     = coalesce(var.service_connection.application_display_name, "${var.project_name}-${var.service_connection.name}")
  owners           = local.effective_owners
  sign_in_audience = "AzureADMyOrg"
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id
  owners    = local.effective_owners
}

resource "azuredevops_serviceendpoint_azurerm" "this" {
  project_id                             = azuredevops_project.this.id
  service_endpoint_name                  = var.service_connection.name
  description                            = var.service_connection.description
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = data.azuread_client_config.current.tenant_id
  azurerm_subscription_id                = var.service_connection.subscription_id
  azurerm_subscription_name              = var.service_connection.subscription_name

  credentials {
    serviceprincipalid = azuread_service_principal.this.client_id
  }

  # Trust is created after Azure DevOps returns the exact issuer and subject.
  features {
    validate = false
  }
}

resource "azuread_application_federated_identity_credential" "this" {
  application_id = azuread_application.this.id
  display_name   = "azure-devops-service-connection"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = azuredevops_serviceendpoint_azurerm.this.workload_identity_federation_issuer
  subject        = azuredevops_serviceendpoint_azurerm.this.workload_identity_federation_subject
}

resource "azuredevops_variable_group" "this" {
  for_each = var.variable_groups

  project_id   = azuredevops_project.this.id
  name         = each.value.name
  description  = each.value.description
  allow_access = each.value.allow_access

  dynamic "key_vault" {
    for_each = each.value.key_vault == null ? [] : [each.value.key_vault]
    content {
      name                = key_vault.value.name
      service_endpoint_id = azuredevops_serviceendpoint_azurerm.this.id
      search_depth        = key_vault.value.search_depth
    }
  }

  dynamic "variable" {
    for_each = each.value.key_vault == null ? each.value.variables : { for name in each.value.secret_names : name => null }
    content {
      name  = variable.key
      value = variable.value
    }
  }

  depends_on = [azuread_application_federated_identity_credential.this]
}
