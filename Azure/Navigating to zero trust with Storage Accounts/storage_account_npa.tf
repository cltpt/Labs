resource "azurerm_resource_group" "zerotrust_storageaccount0" {
  name     = "zerotrust_storageaccount_rg0"
  location = "East US"
}

resource "azurerm_storage_account" "stgactnpa" {
  # You'll need to change the name of your storage account in the event that someone has already used this name
  name                     = "ztstorageaccountnpa"
  resource_group_name      = azurerm_resource_group.zerotrust_storageaccount1.name
  location                 = azurerm_resource_group.zerotrust_storageaccount1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # This configuration setting disables blob public access
  allow_nested_items_to_be_public = false

  depends_on = [azurerm_resource_group.zerotrust_storageaccount1]
}