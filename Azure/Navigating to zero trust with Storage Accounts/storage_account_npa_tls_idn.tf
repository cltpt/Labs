resource "azurerm_resource_group" "zerotrust_storageaccount2" {
  name     = "zerotrust_storageaccount_rg2"
  location = "East US"
}

resource "azurerm_storage_account" "stgacttlsidn" {
  # You'll need to change the name of your storage account in the event that someone has already used this name
  name                     = "ztstorageaccounttlsidn"
  resource_group_name      = azurerm_resource_group.zerotrust_storageaccount2.name
  location                 = azurerm_resource_group.zerotrust_storageaccount2.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # In this configuration we define the minimum TLS version of 1.2.  This is a requirement for many compliance frameworks so it is a good default security configuration to implement
  min_tls_version = "TLS1_2"

  # This configuration setting disables blob public access
  allow_nested_items_to_be_public = false

  # Creating a system assigned managed identity
  identity {
    # You can also choose a user assigned managed identity by changing this to UserAssigned
    type = "SystemAssigned"
    # If you choose a UserAssigned Managed identity (UAMI) you'll need to set the identity_ids of the UAMIs below
    # identity_ids = [ my_id ]
  }

  depends_on = [azurerm_resource_group.zerotrust_storageaccount2]
}