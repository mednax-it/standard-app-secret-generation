terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "app_registration_id" {
  type=string
}

variable "resource_group_name" {
  type=string
}

variable "key_vault_name" {
  type=string
}

variable "key_name" {
  type=string
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_key_vault" "kv" {
  name = var.key_vault_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_key_vault_secrets" "secrets" {
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_secret" "secret" {
  count = (contains(data.azurerm_key_vault_secrets.secrets.names, var.key_name) ? 1 : 0)
  name = var.key_name
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azuread_application" "appreg" {
  client_id = var.app_registration_id
}

resource "azuread_application_password" "client_secret" {
  count = try(data.azurerm_key_vault_secret.secret[0].name == var.key_name ? 0 : 1, 1)
  application_id = data.azuread_application.appreg.id
  display_name = var.key_name
  provisioner "local-exec" {
    when="create"
    command = "az ad app credential reset --id '${self.id}}' --append --display-name 'long-life' --years 100"
    
  }
}

resource "azurerm_key_vault_secret" "client_secret" {
  count = try(data.azurerm_key_vault_secret.secret[0].name == var.key_name ? 0 : 1, 1)
  name = var.key_name
  value = resource.azuread_application_password.client_secret[0].value
  key_vault_id = data.azurerm_key_vault.kv.id
  expiration_date = formatdate("YYYY-MM-DD", time_offset.future_date.rfc3339)
  tags = { "phase": local.phase }
}

resource "null_resource" "cleanse_state" {
  provisioner "local-exec" {
    command = "rm -rf *.tfstate"
  }
}


# For the expiration date on the Keyvault
resource "time_offset" "future_date" {
  offset_years = 100
}

locals {
  app_name = data.azuread_application.appreg.name
  is_prod = contains("prod", local.app_name) || (!contains("non-prod", local.app_name) && !contains("dev", local.app_name) && !contain("stage", local.app_name) && !contain("test", local.app_name))
  phase = is_prod ? "Prod" : "PPE"
}