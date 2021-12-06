terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.88.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=2.12.0"
    }
  }
}

# Configure the Active Directory resources
provider "azuread" {}

data "azuread_client_config" "current" {}

resource "azuread_application" "greeter_app" {
  display_name = "greeter-app"
  owners       = [data.azuread_client_config.current.object_id]
}


resource "random_string" "password" {
  length  = 32
  special = true
}
resource "azuread_application_password" "aks_sp_pwd" {
  application_object_id = azuread_application.greeter_app.object_id
}

resource "azuread_service_principal" "aks_sp" {
  application_id = azuread_application.greeter_app.application_id
}

provider "azurerm" {
  features {}
}


# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "greeter-app"
  location = "West Europe"
}

resource "azurerm_container_registry" "acr" {
  name                = "greeter"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_kubernetes_cluster" "greeter_app" {
  name                   = "greeter-app"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  dns_prefix             = "greeter-app"
  role_based_access_control {
    enabled = true
    azure_active_directory {
        managed = true
    }
  }

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  service_principal {
    client_id     = azuread_application.greeter_app.application_id
    client_secret = azuread_application_password.aks_sp_pwd.value
  }

  tags = {
    Environment = "Development"
  }
}

resource "azurerm_role_assignment" "acrpull_role" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azuread_service_principal.aks_sp.object_id
  skip_service_principal_aad_check = true
}
