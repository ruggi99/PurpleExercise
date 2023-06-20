﻿param(
    [string]$Hostname
     )

Import-Module = "Utils\Add-ADUser.ps1"

# AD INITIALIZATION
# Define configuration file path
$configPath = "AD_network.json"

# Check configuration file path
if (-not (Test-Path -Path $configPath)) {
# Configuration file not found
throw "Configuration file not found. Check file path."
}

# Load configuration file
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# Define the domain name
$Domain = $config.domain.name

# Define users limit
$UsersLimit = $config.domain.usersLimit

# Create credential object for the local admin and the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin), (ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)

$SamAccountName,$password = AddADUser

        Invoke-Command -ComputerName $Hostname -Credential $admin -ScriptBlock {
	    cmd /c net localgroup "Administrators" $using:SamAccountName /add | Out-Null
	}


}