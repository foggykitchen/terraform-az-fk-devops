terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "= 1.16.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "= 3.10.0"
    }
  }
}
