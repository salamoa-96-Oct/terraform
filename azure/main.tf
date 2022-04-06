terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.0.2"
    }
  }
}

provider "azurerm" {
  # Configuration options
}

resource "azurerm_resource_group" "mjs-test-RG" {
  name     = "mjs-test-RG"
  location = "West Europe"
}

