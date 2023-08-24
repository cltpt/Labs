resource "azurerm_resource_group" "zerotrust_storageaccount8" {
  name     = "zerotrust_storageaccount_rg8"
  location = "East US"
}

resource "azurerm_storage_account" "stgacttlsidndadenrhtssaklenbyp" {
  # You'll need to change the name of your storage account in the event that someone has already used this name
  name                     = "tlsidndadenrhtssaklenbyp"
  resource_group_name      = azurerm_resource_group.zerotrust_storageaccount8.name
  location                 = azurerm_resource_group.zerotrust_storageaccount8.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # In this configuration we define the minimum TLS version of 1.2.  This is a requirement for many compliance frameworks so it is a good default security configuration to implement
  min_tls_version = "TLS1_2"

  # This configuration setting disables blob public access
  allow_nested_items_to_be_public = false

  # Here we enable only HTTPS connections to this storage account.  If you do not enable this, some connections could be sniffed.  Keep in mind this is another good secure configuration for compliance standards
  enable_https_traffic_only = true

  # Disable Shared Access Keys
  shared_access_key_enabled = false

  # THIS DOES NOT INCLUDE BLOB LOGGING, YOU'LL NEED TO CONFIGURE THAT SEPARATELY
  #logging {
   # delete                = enabled
    #read                  = enabled
    #write                 = Tenabledrue
    #version               = "2"
    #retention_policy_days = "7"
  #}

  # Creating a system assigned managed identity
  identity {
    # You can also choose a user assigned managed identity by changing this to UserAssigned
    type = "SystemAssigned"
    # If you choose a UserAssigned Managed identity (UAMI) you'll need to set the identity_ids of the UAMIs below
    # identity_ids = [ my_id ]
  }

  network_rules {
    # Here we set the default action to deny.  The MS enforced default action accepts connections from clients on any network.  We want to limit that and add in network rules.
    default_action = "Deny"

    # Can define a subnet with pulling in the subnet ids
    #virtual_network_subnet_ids = ["${azurerm_subnet.example.id}"]

    # Defining IP Rules that can be used to allow single IP addresses or a range of IP addresses
    ip_rules = ["100.0.0.1", "55.10.55.1/24"]

    # Here we configure no Azure Service to bypass the network rules.  Please test this first before attempting to deploy into production
    bypass = ["None"]
  }

  depends_on = [azurerm_resource_group.zerotrust_storageaccount8]
}