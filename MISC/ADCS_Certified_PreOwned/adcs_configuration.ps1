$scriptCode = {    
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
}

# Create the script file and write the code into it
$scriptCode | Out-File -FilePath "C:\Users\adcs_config.ps1" -Force