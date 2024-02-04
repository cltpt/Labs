resource "azurerm_bastion_host" "bastion_host" {
  name                = "cpowl_bastion"
  location            = azurerm_resource_group.cpowl.location
  resource_group_name = azurerm_resource_group.cpowl.name

  ip_configuration {
    name                 = "bastionip"
    subnet_id            = azurerm_subnet.Azure_Bastion_Subnet.id
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}
