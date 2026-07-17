# i want this subnet to be 10.10.2.0/24

resource "azurerm_linux_virtual_machine_scale_set" "web-vmss" {
  name = "web-vmss-${var.name_prefix}"
  location = var.location
  resource_group_name = var.resource_group_name

  sku = var.vmss_sku
  instances = var.instance_count
  zones = var.availability_zones

  admin_username = var.admin_username
  disable_password_authentication = true

  upgrade_mode = "Automatic"

  admin_ssh_key {
    username = var.admin_username
    public_key = var.ssh_public_key
  }

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "0001-com-ubuntu-server-jammy"
    sku = "22_04-lts"
    version = "latest"
  }

  os_disk {
    storage_account_type = "StandardSSD_LRS"
    caching = "ReadWrite"
  }

  network_interface {
    name = "nic-vmss-web"
    primary = true

    ip_configuration {
      name = "ipconfig-vmss-web"
      primary = true
      subnet_id = var.subnet_id

      application_gateway_backend_address_pool_ids = [
        var.appgw_backend_address_pool_id
      ]
    }
  }

  custom_data = base64encode(templatefile("${path.module}/templates/cloud-init.sh.tpl",
  {
    resume_name = var.resume_name
    internal_lb_frontend_ip = var.internal_lb_frontend_ip
  }))

  tags = var.tags
}