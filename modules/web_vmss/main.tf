# i want this subnet to be 10.10.2.0/24

resource "azurerm_linux_virtual_machine_scale_set" "web-vmss" {
  name = "vmss-${local.name_prefix}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku = var.vmss_sku
  instances = var.vmss_initial_instance_count
  zones = ["1", "2", "3"]

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
    name = "nic-vmss"
    primary = true

    ip_configuration {
      name = "ipconfig-vmss"
      primary = true
      subnet_id = azurerm_subnet.vmss_subnet.id

      application_gateway_backend_address_pool_ids = [
        one(azurerm_application_gateway.appgw.backend_address_pool).id
      ]
    }
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    
    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head>
        <title> Azure Resume Project</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                background: #f4f7fb;
                margin: 0;
                padding: 40px;
                color: #222;
            }
            .card {
                background: white;
                padding: 32px;
                border-radius: 12px;
                max-width: 800px;
                margin: 800px;
                box-shadow: 0 8px 30px rgba(0,0,0,0.08);
            }
            h1 {
                color: #0078d4
            }
            </style>
        </head>
        <body>
            <div class="card">
                <h1>${var.resume_name}</h1>
                <h2>Azure Cloud Engineering Portfolio</h2>
                <p>This resume website is running on an Azure Virtual Machine Scale Set behind an Application Gateway WAF. </p>
                <p>The infrastructure was deployed using Terraform.</p>
                <p>Backend instances are private and reachable administratively through Azure Bastion</p>
            </div>
        </body>
    </html>
HTML

        systemctl enable nginx
        systemctl restart nginx
    EOF
    )

    tags = local.common_tags

    depends_on = [
        azurerm_application_gateway.appgw
    ]
}