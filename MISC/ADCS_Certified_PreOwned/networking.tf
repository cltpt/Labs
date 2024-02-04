###############################
## Setting up resource group ##
###############################

resource "azurerm_resource_group" "cpowl" {
  name     = "CertifiedPreOwnedLab"
  location = "eastus2"
}

###############################
## Setting up resource group ##
###############################

###############################
## Setting up VNET / Subnets ##
###############################

resource "azurerm_virtual_network" "cpowl_vnet" {
  name                = "cpowl_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.cpowl.location
  resource_group_name = azurerm_resource_group.cpowl.name
}

resource "azurerm_subnet" "cpowl_subnet" {
  name                 = "cpowl_subnet"
  resource_group_name  = azurerm_resource_group.cpowl.name
  virtual_network_name = azurerm_virtual_network.cpowl_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "Azure_Bastion_Subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.cpowl.name
  virtual_network_name = azurerm_virtual_network.cpowl_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

###############################
## Setting up VNET / Subnets ##
###############################

#####################
## Setting up NSGs ##
#####################

resource "azurerm_network_security_group" "cpowl_nsg" {
  name                = "cpowl_nsg"
  location            = azurerm_resource_group.cpowl.location
  resource_group_name = azurerm_resource_group.cpowl.name
}

resource "azurerm_subnet_network_security_group_association" "asdf" {
  subnet_id                 = azurerm_subnet.cpowl_subnet.id
  network_security_group_id = azurerm_network_security_group.cpowl_nsg.id
}

resource "azurerm_network_security_rule" "allow_bastion_nsg_rule" {
  name                        = "AllowBastion"
  priority                    = 1004
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*" #Can we get the User IP stored within a variable and then inputted here?
  network_security_group_name = azurerm_network_security_group.cpowl_nsg.name
  resource_group_name         = azurerm_resource_group.cpowl.name
}

#####################
## Setting up NSGs ##
#####################

#############################
## Public IP address setup ##
#############################

resource "azurerm_public_ip" "public_ip" {
  name                = "cpowl_public_ip"
  location            = azurerm_resource_group.cpowl.location
  resource_group_name = azurerm_resource_group.cpowl.name
  allocation_method   = "Static"
  sku                 = "Standard"
  lifecycle {
    create_before_destroy = true
  }
}

#############################
## Public IP address setup ##
#############################