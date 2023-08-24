resource "azurerm_resource_group" "zerotrust_storageaccount1" {
  name     = "zerotrust_storageaccount_rg1"
  location = "East US"
}

resource "azurerm_storage_account" "stgacttls" {
  # You'll need to change the name of your storage account in the event that someone has already used this name
  name                     = "ztstorageaccounttls"
  resource_group_name      = azurerm_resource_group.zerotrust_storageaccount1.name
  location                 = azurerm_resource_group.zerotrust_storageaccount1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # In this configuration we define the minimum TLS version of 1.2.  This is a requirement for many compliance frameworks so it is a good default security configuration to implement
  min_tls_version = "TLS1_2"

  # This configuration setting disables blob public access
  allow_nested_items_to_be_public = false

  depends_on = [azurerm_resource_group.zerotrust_storageaccount1]
}