output "backend_address_pool_id" {
    description = "ID of the internal load balancer's backend address pool that the app tier VMSS attaches to."
    value = azurerm_lb_backend_address_pool.app.id
}

output "frontend_private_ip" {
    description = "Private IP address of the internal load balancer frontend."
    value = azurerm_lb.internal_lb.private_ip_address
}
