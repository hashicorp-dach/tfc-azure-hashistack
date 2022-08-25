locals {
  nomad_apt   = length(split("+", var.nomad_version)) == 2 ? "nomad-enterprise" : "nomad"
  consul_apt  = length(split("+", var.consul_version)) == 2 ? "consul-enterprise" : "consul"
  vault_apt   = length(split("+", var.vault_version)) == 2 ? "vault-enterprise" : "vault"
  kms_key_name  = var.vault_enabled ? azurerm_key_vault_key.hashistack_kms_key.0.name : "NULL"
  cert        = var.vault_tls_enabled ? tls_locally_signed_cert.vault.0.cert_pem : "NULL"
  key         = var.vault_tls_enabled ? tls_private_key.vault.0.private_key_pem : "NULL"
  ca_cert     = var.vault_tls_enabled ? tls_private_key.ca.0.public_key_pem : "NULL"
  protocol    = var.vault_tls_enabled ? "https" : "http"
  tls_disable = var.vault_tls_enabled ? "false" : "true"
  
  fqdn_tls    = [for i in range(var.server_count) : format("%s-%02d.%s", var.server_name, i +1, var.dns_domain)] 
}

resource "azurerm_public_ip" "hashistack_server_public_ip" {
  count = var.server_count
  name                = "hashistack_public_ip_${count.index}"
  resource_group_name = azurerm_resource_group.hashistack_resource_group.name
  location            = azurerm_resource_group.hashistack_resource_group.location
  allocation_method   = "Static"

  tags = {
    environment = "hashistack"
  }
}

resource "azurerm_network_interface" "hashistack_server_net_interface" {
  count = var.server_count
  name                = "hashistack_server_nic_${count.index}"
  location            = azurerm_resource_group.hashistack_resource_group.location
  resource_group_name = azurerm_resource_group.hashistack_resource_group.name

  ip_configuration {
    name                          = "hashistack_server_${count.index}"
    subnet_id                     = azurerm_subnet.hashistack_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.hashistack_server_public_ip.*.id[count.index]
  }
}

resource "azurerm_linux_virtual_machine" "hashistack_server_vm" {
  count = var.server_count
  name                = "example-machine-${count.index}"
  resource_group_name = azurerm_resource_group.hashistack_resource_group.name
  location            = azurerm_resource_group.hashistack_resource_group.location
  size                = var.instance_type
  admin_username      = "hashistack"
  network_interface_ids = [
    azurerm_network_interface.hashistack_server_net_interface.*.id[count.index],
  ]

  identity {
    type = "UserAssigned"
    identity_ids = azurerm_user_assigned_identity.vault.*.id
  }
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
  
  user_data = base64encode(templatefile("${path.root}/templates/server.sh", 
    {
        server_count            = var.server_count
        data_dir                = var.data_dir
        datacenter              = var.datacenter
        region                  = var.region
        node_name               = format("${var.server_name}-%02d",count.index+1)
        nomad_join              = var.tag_value
        nomad_enabled           = var.nomad_enabled
        nomad_version           = var.nomad_version
        nomad_apt               = local.nomad_apt
        nomad_lic               = var.nomad_lic
        nomad_bootstrap         = var.nomad_bootstrap
        consul_enabled          = var.consul_enabled
        consul_version          = var.consul_version
        consul_apt              = local.consul_apt
        consul_lic              = var.consul_lic
        vault_enabled           = var.vault_enabled
        vault_version           = var.vault_version
        vault_apt               = local.vault_apt
        vault_lic               = var.vault_lic
        azure_key_name          = local.kms_key_name
        azure_key_vault_name    = azurerm_key_vault.hashistack_key_vault.name
        azure_tenant_id         = azurerm_user_assigned_identity.vault.tenant_id
        azure_subscription_id   = data.azurerm_client_config.current.subscription_id
        azure_client_id         = azurerm_user_assigned_identity.vault.client_id
        azure_region            = var.azure_region
        protocol                = local.protocol
        tls_disable             = local.tls_disable
        cert                    = local.cert 
        key                     = local.key
        ca_cert                 = local.ca_cert
        dns_domain              = var.dns_domain
    } 
  ))
}