[CmdletBinding()]

param 
( 
    [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$Domain_DNSName,
    [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$Domain_NETBIOSName,
    [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [String]$SafeModeAdministratorPassword
)

# Store the Safe Mode Admin password as a Secure-String
$SMAP = ConvertTo-SecureString -AsPlainText $SafeModeAdministratorPassword -Force

# Define the PowerShell code to be written into the script file
$scriptCode = {
    #####User, Group, Kerberos setup#####
    #-----------------------------------#
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

    #####User, Group, Kerberos setup#####
    #-----------------------------------#
}

# Create the script file and write the code into it
# Have to put this file in the Users directory and not directly in our users path because the VM Extenstion fails to find the path
$scriptCode | Out-File -FilePath "C:\Users\UserAndGroupAndKerberos.ps1" -Force

# Install Active Directory Domain Services feature
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote the server to a domain controller
Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -DomainMode "WinThreshold" -DomainName $Domain_DNSName -DomainNetbiosName $Domain_NETBIOSName -ForestMode "WinThreshold" -InstallDns:$true -LogPath "C:\Windows\NTDS" -NoRebootOnCompletion:$false -SysvolPath "C:\Windows\SYSVOL" -Force:$true -SkipPreChecks -SafeModeAdministratorPassword $SMAP

# Restart the server to complete the AD DS installation
Restart-Computer -Force