# note to self, i want app gw subnet to be 10.0.1.0/24

resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name = "waf-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  policy_settings {
    enabled = true
    mode = "Prevention"
    request_body_check = true
    max_request_body_size_in_kb = 128
    file_upload_limit_in_mb = 100
  }

  managed_rules {
    managed_rule_set {
      type = "OWASP"
      version = "3.2"
    }
  }

  tags = local.common_tags
}

resource "azurerm_application_gateway" "appgw" {
  name = "appgw-${local.name_prefix}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy.id

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 2
  }

  gateway_ip_configuration {
    name = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_ip_configuration {
    name = "appgw-public-frontend"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  frontend_port {
    name = "frontend-port-80"
    port = 80
  }

  backend_address_pool {
    name = "vmss-backend-pool"
  }

  backend_http_settings {
    name = "backend-http-settings"
    cookie_based_affinity = "Disabled"
    path = "/"
    port = 80
    protocol = "Http"
    request_timeout = 30
  }

  http_listener {
    name = "http-listener"
    frontend_ip_configuration_name = "appgw-public-frontend"
    frontend_port_name = "frontend-port-80"
    protocol = "Http"
  }

  request_routing_rule {
    name = "http-routing-rule"
    rule_type = "Basic"
    http_listener_name = "http-listener"
    backend_address_pool_name = "vmss-backend-pool"
    backend_http_settings_name = "backend-http-settings"
    priority = 100
  }

  tags = local.common_tags
}