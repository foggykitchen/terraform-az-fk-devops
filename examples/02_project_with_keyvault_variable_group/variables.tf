variable "organization_url" {
  description = "Existing Azure DevOps organization URL."
  type        = string
}

variable "tenant_id" {
  description = "Existing Entra tenant ID."
  type        = string
}

variable "subscription_id" {
  description = "Existing target Azure subscription ID."
  type        = string
}

variable "subscription_name" {
  description = "Target subscription display name."
  type        = string
}

variable "project_name" {
  description = "Azure DevOps project name."
  type        = string
  default     = "fk-devops-demo"
}

variable "rbac_scope" {
  description = "Existing subscription or resource group resource ID for pipeline access."
  type        = string
}

variable "role_definition_name" {
  description = "Role granted to the pipeline service principal."
  type        = string
  default     = "Reader"
}

variable "key_vault_name" {
  description = "Globally unique Key Vault name."
  type        = string
}

variable "resource_group_name" {
  description = "Existing resource group for the Key Vault."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "westeurope"
}

variable "link_variable_group" {
  description = "Enable only after the vault has been populated outside Terraform."
  type        = bool
  default     = false
}

variable "secret_names" {
  description = "Existing enabled Key Vault secret names; never values."
  type        = set(string)
  default     = []
}
