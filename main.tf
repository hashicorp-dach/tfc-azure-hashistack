provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "hashistack_resource_group" {
  name     = "dach-se-hashistack"
  location = "West Europe"
}

resource "azurerm_virtual_network" "hashistack_network" {
  name                = "hashistack_network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.hashistack_resource_group.location
  resource_group_name = azurerm_resource_group.hashistack_resource_group.name
}

resource "azurerm_subnet" "hashistack_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.hashistack_resource_group.name
  virtual_network_name = azurerm_virtual_network.hashistack_network.name
  address_prefixes     = ["10.0.2.0/24"]
}