$scriptCode = {
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

    ###################################################
    ##### Software installs and Remote Management #####
    ###################################################

    # Add user to Remote Desktop Users group
    # This needs to be run as a domain admin
    Add-LocalGroupMember -Group 'Remote Desktop Users' -Member 'testdomain.local\TestUser'

    # Install git
    #curl -o gitinstall.exe https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe
    
    # Install Visual Studio Community
    #curl -o visualstudioinstall.exe https://aka.ms/vs/17/release/vs_community.exe

    # This should be run from a command prompt
    #git clone https://github.com/GhostPack/Rubeus.git

    # This should be run from a command prompt
    #git clone https://github.com/GhostPack/Certify.git
    
    # Simply open up the project .sln, choose "Release", and build

    ###################################################
    ##### Software installs and Remote Management #####
    ###################################################

    ###########################
    ##### Compile and Run #####
    ###########################

    # Run the Rubeus command to get the .kirbi
    #Rubeus.exe asktgt /user:adcsuser /certificate:cert.pfx /password:Password123! /ptt

    ###########################
    ##### Compile and Run #####
    ###########################
}

# Create the script file and write the code into it
$scriptCode | Out-File -FilePath "C:\Users\user_config.ps1" -Force