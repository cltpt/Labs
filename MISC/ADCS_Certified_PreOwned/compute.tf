#############################
## Setting up NICs for VMs ##
#############################

resource "azurerm_network_interface" "dc_vm_nic" {
  name                = "dc_nic"
  location            = azurerm_resource_group.cpowl.location
  resource_group_name = azurerm_resource_group.cpowl.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.cpowl_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "adcs_vm_nic" {
  name                = "adcs_nic"
  location            = azurerm_resource_group.cpowl.location
  resource_group_name = azurerm_resource_group.cpowl.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.cpowl_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "cpowl_user_vm_nic" {
  name                = "cpowl_user_vm_nic"
  location            = azurerm_resource_group.cpowl.location
  resource_group_name = azurerm_resource_group.cpowl.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.cpowl_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
#############################
## Setting up NICs for VMs ##
#############################

##################################
## Setting up compute resources ##
##################################
resource "azurerm_windows_virtual_machine" "dc_vm" {
  name                = "DCVM"
  resource_group_name = azurerm_resource_group.cpowl.name
  location            = azurerm_resource_group.cpowl.location
  size                = "Standard_B2s"
  admin_username      = var.dc_admin
  admin_password      = var.dc_pass
  network_interface_ids = [
    azurerm_network_interface.dc_vm_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_windows_virtual_machine" "adcs_vm" {
  name                = "ADCSVM"
  resource_group_name = azurerm_resource_group.cpowl.name
  location            = azurerm_resource_group.cpowl.location
  size                = "Standard_B2s"
  admin_username      = var.adcs_admin
  admin_password      = var.adcs_pass
  network_interface_ids = [
    azurerm_network_interface.adcs_vm_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_windows_virtual_machine" "cpowl_user_vm" {
  name                = "USERVM"
  resource_group_name = azurerm_resource_group.cpowl.name
  location            = azurerm_resource_group.cpowl.location
  size                = "Standard_B2s"
  admin_username      = var.user_admin
  admin_password      = var.user_pass
  network_interface_ids = [
    azurerm_network_interface.cpowl_user_vm_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

##################################
## Setting up compute resources ##
##################################

##############################
## Setting up VM extensions ##
##############################

resource "azurerm_virtual_machine_extension" "install_ad" {
  name                 = "install_ad"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = <<SETTINGS
  {    
    "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.domainConfig.rendered)}')) | Out-File -filepath domainConfig.ps1\" && powershell -ExecutionPolicy Unrestricted -File domainConfig.ps1 -Domain_DNSName ${data.template_file.domainConfig.vars.Domain_DNSName} -Domain_NETBIOSName ${data.template_file.domainConfig.vars.Domain_NETBIOSName} -SafeModeAdministratorPassword ${data.template_file.domainConfig.vars.SafeModeAdministratorPassword}"
  }
  SETTINGS
}

resource "azurerm_virtual_machine_extension" "add_script_adcs" {
  name                 = "add_script_adcs"
  virtual_machine_id   = azurerm_windows_virtual_machine.adcs_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = <<SETTINGS
  {    
    "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.adcs_configuration.rendered)}')) | Out-File -filepath adcs_configuration.ps1\" && powershell -ExecutionPolicy Unrestricted -File adcs_configuration.ps1"
  }
  SETTINGS
}

resource "azurerm_virtual_machine_extension" "add_script_uservm" {
  name                 = "add_script_uservm"
  virtual_machine_id   = azurerm_windows_virtual_machine.cpowl_user_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = <<SETTINGS
  {    
    "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.userVMConfig.rendered)}')) | Out-File -filepath userVMConfig.ps1\" && powershell -ExecutionPolicy Unrestricted -File userVMConfig.ps1"
  }
  SETTINGS
}
##############################
## Setting up VM extensions ##
##############################