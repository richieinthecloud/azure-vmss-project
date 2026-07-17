# Internal Standard Load Balancer distributing traffic from the web tier VMSS
# to the app tier. Sits in the app subnet with a private, dynamically 
# assigned frontend IP. 

resource "azurerm_lb" "internal_lb" {
    name = "ilb-app${var.name_prefix}"
    location = var.location
    resource_group_name = var.resource_group_name
    sku = "Standard"

    frontend_ip_configuration {
        name = "ilb-frontend-ip"
        subnet_id = var.subnet_id
        private_ip_address_allocation = "Dynamic"
        zones = var.availability_zones
    }

    tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "app" {
    name = "app-vmss-backend-pool"
    loadbalancer_id = azurerm_lb.internal_lb.id
}

resource "azurerm_lb_probe" "app_http" {
    name = "app-http-probe"
    loadbalancer_id = azurerm_lb.internal_lb.id
    protocol = "Tcp"
    port = var.backend_port
    interval_in_seconds = 5
    number_of_probes = 2
}

resource "azurerm_lb_rule" "app_http" {
    name = "app-http-rule"
    loadbalancer_id = azurerm_lb.internal_lb.id
    protocol = "Tcp"
    frontend_port = var.backend_port
    backend_port = var.backend_port
    frontend_ip_configuration_name = "ilb-frontend-ip"
    backend_address_pool_ids = [azurerm_lb_backend_address_pool.app.id]
    probe_id = azurerm_lb_probe.app_http.id
}