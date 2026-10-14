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
  default     = "fk-devops-github-demo"
}

variable "resource_group_name" {
  description = "Resource Group created by this example."
  type        = string
  default     = "foggykitchen-github-rg"
}

variable "location" {
  description = "Azure region for the example Resource Group."
  type        = string
  default     = "westeurope"
}

variable "role_definition_name" {
  description = "Role granted to the pipeline service principal."
  type        = string
  default     = "Reader"
}
