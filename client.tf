resource "azurerm_public_ip" "hashistack_client_public_ip" {
  count = var.client_count
  name                = "hashistack_client_public_ip_${count.index}"
  resource_group_name = azurerm_resource_group.hashistack_resource_group.name
  location            = azurerm_resource_group.hashistack_resource_group.location
  allocation_method   = "Static"

  tags = {
    environment = "hashistack"
  }
}

resource "azurerm_network_interface" "hashistack_client_net_interface" {
  count = var.client_count
  name                = "hashistack_client_nic_${count.index}"
  location            = azurerm_resource_group.hashistack_resource_group.location
  resource_group_name = azurerm_resource_group.hashistack_resource_group.name

  ip_configuration {
    name                          = "internal__${count.index}"
    subnet_id                     = azurerm_subnet.hashistack_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.hashistack_client_public_ip.*.id[count.index]
  }
  
  tags = {
    auto_join = var.tag_value
  }
}

resource "azurerm_linux_virtual_machine" "hashistack_client_vm" {
  count = var.client_count
  name                = format("${var.client_name}-%02d", count.index + 1)
  resource_group_name = azurerm_resource_group.hashistack_resource_group.name
  location            = azurerm_resource_group.hashistack_resource_group.location
  size                = "Standard_B1s"
  admin_username      = "hashistack"
  network_interface_ids = [
    azurerm_network_interface.hashistack_client_net_interface.*.id[count.index],
  ]

  admin_ssh_key {
    username   = "hashistack" #upload an sshkey to the azure sub
    public_key = data.azurerm_ssh_public_key.hashistack_public_key.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = var.ubuntu_server_sku
    version = "latest"
  }
  
  user_data = base64encode(templatefile("${path.root}/templates/client.sh", 
    {
        client_count        = var.client_count
        data_dir            = var.data_dir
        datacenter          = var.datacenter
        region              = var.region
        client              = var.client
        nomad_join          = var.tag_value
        node_name           = format("${var.client_name}-%02d", count.index +1)
        nomad_enabled       = var.nomad_enabled
        nomad_version       = var.nomad_version
        nomad_apt           = local.nomad_apt
        consul_enabled      = var.consul_enabled
        consul_version      = var.consul_version
        consul_apt          = local.consul_apt
        consul_lic          = var.consul_lic
        consul_enabled      = var.consul_enabled
        nomad_enabled       = var.nomad_enabled
        azure_tenant_id         = azurerm_user_assigned_identity.vault.tenant_id
        azure_subscription_id   = data.azurerm_client_config.current.subscription_id  
    } 
  ))
}