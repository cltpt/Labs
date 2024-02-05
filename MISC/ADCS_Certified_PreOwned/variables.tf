variable "sp_secret" {
  description = "Service Principal Secret"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Tenant ID"
  type        = string
  sensitive   = true
}

variable "app_id" {
  description = "Application ID"
  type        = string
  sensitive   = true
}

variable "subscription_id" {
  description = "Subscription ID"
  type        = string
  sensitive   = true
}

variable "dc_pass" {
  description = "Domain Controller Pass"
  type        = string
  sensitive   = true
}

variable "adcs_pass" {
  description = "ADCS Pass"
  type        = string
  sensitive   = true
}

variable "user_pass" {
  description = "User Pass"
  type        = string
  sensitive   = true
}

variable "user_admin" {
  description = "User Admin name"
  type        = string
  sensitive   = true
}

variable "dc_admin" {
  description = "DC Admin name"
  type        = string
  sensitive   = true
}

variable "adcs_admin" {
  description = "ADCS Admin name"
  type        = string
  sensitive   = true
}

variable "Domain_DNSName" {
  description = "FQDN for the Active Directory forest root domain"
  type        = string
  sensitive   = false
}

variable "netbios_name" {
  description = "NETBIOS name for the AD domain"
  type        = string
  sensitive   = false
}

variable "SafeModeAdministratorPassword" {
  description = "Password for AD Safe Mode recovery"
  type        = string
  sensitive   = true
}

# Variable input for the domain_configuration.ps1 script
data "template_file" "domainConfig" {
  template = file("domainConfig.ps1")
  vars = {
    Domain_DNSName                = "${var.Domain_DNSName}"
    Domain_NETBIOSName            = "${var.netbios_name}"
    SafeModeAdministratorPassword = "${var.SafeModeAdministratorPassword}"
  }
}

# Variable input for the adcs_configuration.ps1 script
data "template_file" "adcs_configuration" {
  template = file("adcs_configuration.ps1")
}

# Variable input for the userVMConfig.ps1 script
data "template_file" "userVMConfig" {
  template = file("userVMConfig.ps1")
}