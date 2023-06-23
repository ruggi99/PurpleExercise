
param(
    [string]$Hostname
     )

	# AD INITIALIZATION
	# Define configuration file path
	$configPath = ".\AD_network.json"

	# Check configuration file path	
	if (-not (Test-Path -Path $configPath)) {
  	# Configuration file not found
  	throw "Configuration file not found. Check file path."  	
}

	# Load configuration file
	$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

	# Create credential object for the local admin and the domain admin
	$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin), (ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)

    Write-Host $Hostname
    
    Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock {
		
		$ComputerAccount = (Get-ADComputer -Filter {DNSHostName -eq $using:Hostname}).SamAccountName

        Get-ADComputer -Identity $ComputerAccount | Set-ADAccountControl -TrustedForDelegation $true
    }
      
      


