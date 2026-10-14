variable "project_name" {
  description = "Azure DevOps project name."
  type        = string
  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name must not be blank."
  }
}

variable "project_description" {
  description = "Azure DevOps project description."
  type        = string
  default     = null
}

variable "project_visibility" {
  description = "Azure DevOps project visibility: private or public."
  type        = string
  default     = "private"
  validation {
    condition     = contains(["private", "public"], var.project_visibility)
    error_message = "project_visibility must be private or public."
  }
}

variable "work_item_template" {
  description = "Existing work item template name; empty string uses the organization default."
  type        = string
  default     = "Agile"
}

variable "service_connection" {
  description = "One passwordless Azure Resource Manager service connection and its application name."
  type = object({
    name                     = string
    subscription_id          = string
    subscription_name        = string
    application_display_name = optional(string)
    description              = optional(string, "Managed by Terraform/OpenTofu with workload identity federation")
  })
  validation {
    condition = (
      length(trimspace(var.service_connection.name)) > 0 &&
      length(trimspace(var.service_connection.subscription_name)) > 0 &&
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.service_connection.subscription_id))
    )
    error_message = "Service connection name/subscription_name must not be blank and subscription_id must be a UUID."
  }
}

variable "owners" {
  description = "Additional Entra object IDs owning both the application and service principal."
  type        = set(string)
  default     = []
}

variable "include_current_principal_as_owner" {
  description = "Include the AzureAD provider principal as application and service principal owner."
  type        = bool
  default     = true
}

variable "variable_groups" {
  description = "Plain nonsecret variables or Key Vault secret-name mappings, keyed by logical group name."
  type = map(object({
    name         = string
    description  = optional(string)
    allow_access = optional(bool, false)
    variables    = optional(map(string), {})
    secret_names = optional(set(string), [])
    key_vault = optional(object({
      name         = string
      search_depth = optional(number, 20)
    }))
  }))
  default = {}
  validation {
    condition = alltrue([for group in var.variable_groups :
      group.key_vault == null ? (length(group.variables) > 0 && length(group.secret_names) == 0) : (length(group.variables) == 0 && length(group.secret_names) > 0)
    ])
    error_message = "Each group must contain either nonempty variables without key_vault/secret_names, or key_vault with nonempty secret_names and no variables."
  }
  validation {
    condition = alltrue([for group in var.variable_groups :
      length(trimspace(group.name)) > 0 &&
      alltrue([for name in concat(keys(group.variables), tolist(group.secret_names)) : length(trimspace(name)) > 0]) &&
      (group.key_vault == null ? true : (length(trimspace(group.key_vault.name)) > 0 && group.key_vault.search_depth >= 1 && floor(group.key_vault.search_depth) == group.key_vault.search_depth))
    ])
    error_message = "Group, variable and vault names must not be blank; search_depth must be a positive integer."
  }
  validation {
    condition     = length(distinct([for group in var.variable_groups : group.name])) == length(var.variable_groups)
    error_message = "Variable group names must be unique."
  }
}
