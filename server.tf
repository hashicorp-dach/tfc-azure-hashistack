locals {
  nomad_apt   = length(split("+", var.nomad_version)) == 2 ? "nomad-enterprise" : "nomad"
  consul_apt  = length(split("+", var.consul_version)) == 2 ? "consul-enterprise" : "consul"
  vault_apt   = length(split("+", var.vault_version)) == 2 ? "vault-enterprise" : "vault"
  kms_key_id  = var.vault_enabled ? azurerm_key_vault_key.hashistack_kms_key.0.id : "NULL"
  cert        = var.vault_tls_enabled ? tls_locally_signed_cert.vault.0.cert_pem : "NULL"
  key         = var.vault_tls_enabled ? tls_private_key.vault.0.private_key_pem : "NULL"
  ca_cert     = var.vault_tls_enabled ? tls_private_key.ca.0.public_key_pem : "NULL"
  protocol    = var.vault_tls_enabled ? "https" : "http"
  tls_disable = var.vault_tls_enabled ? "false" : "true"
  
  fqdn_tls    = [for i in range(var.server_count) : format("%s-%02d.%s", var.server_name, i +1, var.dns_domain)] 
}


resource "azurerm_network_interface" "hashistack_net_interface" {
  count = 2
  name                = "example_nic_${count.index}"
  location            = azurerm_resource_group.hashistack_resource_group.location
  resource_group_name = azurerm_resource_group.hashistack_resource_group.name

  ip_configuration {
    name                          = "internal__${count.index}"
    subnet_id                     = azurerm_subnet.hashistack_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.hashistack_public_ip.*.id[count.index]
  }
}

resource "azurerm_public_ip" "hashistack_public_ip" {
  count = 2
  name                = "hashistack_public_ip_${count.index}"
  resource_group_name = azurerm_resource_group.hashistack_resource_group.name
  location            = azurerm_resource_group.hashistack_resource_group.location
  allocation_method   = "Static"

  tags = {
    environment = "test"
  }
}

resource "azurerm_linux_virtual_machine" "hashistack_server_vm" {
  count = 2
  name                = "example-machine-${count.index}"
  resource_group_name = azurerm_resource_group.hashistack_resource_group.name
  location            = azurerm_resource_group.hashistack_resource_group.location
  size                = "Standard_B1s"
  admin_username      = "hashistack"
  network_interface_ids = [
    azurerm_network_interface.hashistack_net_interface.*.id[count.index],
  ]

  admin_ssh_key {
    username   = "hashistack" #upload an sshkey to the azure sub
    public_key = file("~/Documents/SSH-Keys/Antoine-SSH-Key.pub")
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
  
  user_data = base64encode(templatefile("${path.root}/templates/server.sh", 
  {
        server_count        = var.server_count
        data_dir            = var.data_dir
        datacenter          = var.datacenter
        region              = var.region
        node_name           = format("${var.server_name}-%02d",count.index+1)
        nomad_join          = var.tag_value
        nomad_enabled       = var.nomad_enabled
        nomad_version       = var.nomad_version
        nomad_apt           = local.nomad_apt
        nomad_lic           = var.nomad_lic
        nomad_bootstrap     = var.nomad_bootstrap
        consul_enabled      = var.consul_enabled
        consul_version      = var.consul_version
        consul_apt          = local.consul_apt
        consul_lic          = var.consul_lic
        vault_enabled       = var.vault_enabled
        vault_version       = var.vault_version
        vault_apt           = local.vault_apt
        vault_lic           = var.vault_lic
        kms_key_id          = local.kms_key_id
        azure_region        = var.azure_region
        protocol            = local.protocol
        tls_disable         = local.tls_disable
        cert                = local.cert 
        key                 = local.key
        ca_cert             = local.ca_cert
        dns_domain          = var.dns_domain
    } 
  ))
}