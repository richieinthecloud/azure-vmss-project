output "public_ip_address" {
    description = "Static outbound IP. Every request the web and app tiers make to the internet appears to come from this address. This is the address you would give a third party to allow-list."
    value = azurerm_public_ip.nat.ip_address
}

output "nat_gateway_id" {
    description = "The ID of the NAT gateway."
    value = azurerm_nat_gateway.nat.id
}