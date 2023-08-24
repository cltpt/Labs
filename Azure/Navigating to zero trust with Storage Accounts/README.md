## Table of Contents

- [Introduction](#introduction)
- [Before you begin](#beforeyoubegin)
- [Naming Conventions](#namingconventions)
- [Instructions (Click here to skip the explanations)](#instructions)
- [Notes](#notes)

## Introduction

This lab is intended to teach you a handful of security controls on storage accounts that you can utilize to protect your storage accounts.  I've created a naming scheme (see "Naming Conventions" below) for understanding what each terraform file does.  I've also separated out the files with various configuration settings so if you need to only apply a couple of settings, the appropriate file should be there for you.  This is not a be-all-end-all guide to securing your storage accounts so please only use this as a jumping off point for your storage account security journey.  Thank you and enjoy! $\textcolor{orange}{\textsf{common pattern}}$ 

Please note, this lab does NOT include the following items:
* Storage Blob logging (this will need to be configured separately)
* Private Endpoint deployment with Storage Accounts (this will likely be a separate lab as there are more components to this)
* Account Key Expiration Policies
* Utilization of customer managed keys
* Lifecycle Management
* Many more settings / configurations

### Pre-requisites
1. An Azure Subscription
2. Ability to create service principals in Azure Active Directory (AAD)
3. A service principal created for Terraform to create and manage resources [Azure Terraform Install / SP Creation](https://learn.microsoft.com/en-us/azure/developer/terraform/authenticate-to-azure?tabs=bash)
4. Have terraform installed on your local system [Terraform install docs](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### Before you begin
Please do not simply deploy these tf files into production with no editing / configuration changes.  I take no responsibility for you deploying insecure resources and losing data.

Before you begin this lab there are a few things you should understand about Azure Storage accounts and limiting access to them.
1. Storage Account Firewall address range rule limitations of 200 rules
One thing I often advise application teams with 1-10 static IPs that will be accessing Azure Storage Accounts is to simply use the Firewall rules and add in their relevant IP address ranges.  This is NOT an effective method when you have many Azure services attempting to use your storage account.  There is an address limitation as stated in this article [Azure Storage Account Network Security](https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security?tabs=azure-portal), that states "Each storage account supports up to 200 rules.".  If you look at any of the Azure service IP ranges here [Azure Service IP ranges]() you'll notice that with 1 service such as Databricks, you'll cap out your entire allotment of storage account firewall rules.  Keep in mind the limitation is on 200 IP rules and 200 Virtual network rules, but that still does not suffice for most use cases.  Another important note is that IPv6 addresses are not valid to add into the Firewall rules.
2. Use System Assigned Managed Identities where applicable and utilize the Azure RBAC roles
Using System Assigned Managed Identities (SAMI) is a great way to move towards zero trust as you can disable shared access key utilization.  Using a SAMI gives you the opportunity to take advantage of the great RBAC roles Azure has in place.  For example, you can utilize the "Storage Blob Data Contributor to give a user / system access to read, write and delete blobs and blob data.
3. Allow Azure services on the trusted services list to access this storage account
Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. Possible values are any combination of Logging|Metrics|AzureServices (For example, "Logging, Metrics"), or None to bypass none of those traffics.  If you're aiming for a Zero Trust Storage Account you will want to disable this setting
4. Shared Access Key disabled
Terraform uses Shared Key Authorisation to provision Storage Containers, Blobs and other items - when Shared Key Access is disabled, you will need to enable the storage_use_azuread flag in the Provider block to use Azure AD for authentication, however not all Azure Storage services support Active Directory authentication.  Also, a user delegation SAS is authorized with Azure AD and will be permitted on a request to Blob storage when the AllowSharedKeyAccess property is set to false.  A number of Azure services use Shared Key authorization to communicate with Azure Storage. If you disallow Shared Key authorization for a storage account, these services will not be able to access data in that account, and your applications may be adversely affected.  To view this list of services please see this page [Azure Storage Account Disable Shared Access Key](https://learn.microsoft.com/en-us/azure/storage/common/shared-key-authorization-prevent?tabs=portal)
5. Key Expiration policy
We do not configure this setting in this lab but if your organization has requirements for key rotations, please look up how to configuration your account key expiration policy as it will help remind you to rotate your keys on a regular basis (you define the interval).
6. Disable blob public access
Disabling blob public access is a crucial component to a security strategy on storage accounts.  Configuring this will disallow anonymous requests to your storage account blob containers.  This setting can help prevent unauthorized data leaks.  PLEASE apply this setting at a minimum.
7. Databricks environments....
One important lesson I learned when dealing with Storage Accounts in Azure is that if one of your developers has a non-VNET joined Databricks cluster, you're going to have a REALLY hard time trying to enforce network security controls on your Storage Account.  Essentially, to save you the pain and suffering I have to go through every time, if you can encourage your developers to utilize the VNET joined Databricks clusters, please do... [Databricks VNET injection](https://learn.microsoft.com/en-us/azure/databricks/administration-guide/cloud-configurations/azure/vnet-inject)
8. If you don't want to worry about creating all this terraform yourself
Hashicorp offers an Azure Storage Account module here [Github Azure Storage Account Module](https://github.com/Azure-Terraform/terraform-azurerm-storage-account)

### Naming Conventions
To make your life easier instead of having to piecemeal together some terraform configurations for a secure Azure Storage Account I've include a few different default secure templates that you can use to deploy a secure Azure Storage Account.  I've added a naming convention to the files so you can utilize them easily.
* npa = Disables blob public access
* tls = TLS 1.2 has been configured
* idn = A system assigned managed identity has been configured
* dad = Default network rules action has been set to deny
* enr = Virtual or IP network rules have been defined
* hts = HTTPS only is configured
* sak = Shared access keys have been disabled
* len = Logging has been enabled 
* byp = Bypass Azure Services has been disabled

### Instructions
The instructions in this lab are quite simple as you can deploy all of these different storage accounts with some simple terraform commands to see how each resource gets deployed.  AGAIN, do not use this method of authentication to Azure with Terraform in production, this is meant as a nonproduction/sandbox example.

1. Setup your service principal for authentication into terraform [Azure Terraform Docs](https://learn.microsoft.com/en-us/azure/developer/terraform/authenticate-to-azure?tabs=bash)
2. Create your variables file and enter in the service principal credentials, your tenant id, app id, subscrpition id.  Make sure you align your variables name to the variable names in the provider file
3. Go through each tf file and change the names of the storage account names.  These names are likely already taken up by someone else doing this lab and you will be prevented from creating the resources if you fail to change the names. 
4. In your terminal run the following sequence of commands to run your Terraform code
```hcl
terraform init
terraform validate
terraform apply
```
5. !!!IMPORTANT!!! Remove the service principal credentials from your variables file so they are not in code anymore.  Also, it's a good idea to fully delete your service principal after testing so you don't leave any lasting resources

### Additional Information
1: Define Your Zero-Trust Security Model
Before implementing zero trust for your Azure Storage account, it's important to define your security requirements and access policies. Consider the following items: 
* Data Access: Determine who should have access to the storage account and what level of access they require (read, write, delete, etc.).  
* Network Access: Decide which networks or IP ranges should be allowed to access the storage account.  With some features of the Azure Storage Account Firewall rules you don't need to specify IP ranges or even networks.  
* Identity Verification: Determine the authentication mechanism for users and applications accessing the storage account.  
* Encryption: Define encryption requirements for data at rest and in transit.
To create a secure Azure Storage account here are the configuration settings you'll want to configure and evaluate
* Logging: Monitor and audit your storage account use with Azure Monitor, Azure Storage Analytics, and Azure Security Center