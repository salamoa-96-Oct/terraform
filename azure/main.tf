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
  name      = "kuberixtestRG"
  location  = var.resource_group_location
}

resource "azurerm_virtual_network" "mjs-virtual-network" {
  name                = "mjs-virtual-network"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}