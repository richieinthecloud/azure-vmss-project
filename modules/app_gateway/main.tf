resource "azurerm_public_ip" "appgw" {
  name = "pip-appgw-${var.name_prefix}"
  location = var.location
  resource_group_name = var.resource_group_name
  allocation_method = "Static"
  sku = "Standard"
  zones = var.availability_zones

  tags = var.tags
}

resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = "waf-policy-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled = true
    mode    = var.waf_mode
    request_body_check = true
    max_request_body_size_kb = 128
    file_upload_limit_in_mb = 100
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  tags = var.tags
}

resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy.id

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = "appgw-public-frontend"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  frontend_port {
    name = "frontend-port-80"
    port = 80
  }

  frontend_port {
    name = "frontend-port-443"
    port = 443
  }


  backend_address_pool {
    name = "web-vmss-backend-pool"
  }

  backend_http_settings {
    name                  = "backend-http-settings"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "appgw-http-listener"
    frontend_ip_configuration_name = "appgw-public-frontend"
    frontend_port_name             = "frontend-port-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "http-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "appgw-http-listener"
    backend_address_pool_name   = "web-vmss-backend-pool"
    backend_http_settings_name  = "backend-http-settings"
    priority                   = 100
  }

  tags = var.tags
}