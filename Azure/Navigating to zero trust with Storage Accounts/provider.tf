terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # You need to have 3.21.0+ to disallow blob public access
      version = "=3.27.0"
    }
  }
}

provider "azurerm" {
  features {}

  # There are more secure ways to authenticate to Azure rather than a service principal so please do not use this method for production
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.app_id
  client_secret   = var.sp_secret

  # If you want to disable shared access key authorization on your storage accounts you'll need this below line in there
  storage_use_azuread = true
}