provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "hashistack_resource_group" {
  name     = "dach-se-hashistack"
  location = var.azure_region
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

resource "azurerm_ssh_public_key" "hashistack_ssh_key" {
  name                = "hashistack-ssh-key"
  resource_group_name = azurerm_resource_group.hashistack_resource_group.name
  location            = var.azure_region
  public_key          = file("~/Documents/SSH-Keys/Antoine-SSH-Key.pub")
}

data "azurerm_ssh_public_key" "hashistack_public_key" {
  name                = azurerm_ssh_public_key.hashistack_ssh_key.name
  resource_group_name = azurerm_resource_group.hashistack_resource_group.name
}