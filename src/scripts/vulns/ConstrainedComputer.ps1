
param(
    [string]$Hostname
     )

	# Define configuration file path
	$configPath = ".\AD_network.json"

	# Check configuration file path	
	if (-not (Test-Path -Path $configPath)) {
  	# Configuration file not found
  	throw "Configuration file not found. Check file path."  	
}

	# Load configuration file
	$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

	# Define the domain name
	$Domain = $config.domain.name

	# Create credential object for the local admin and the domain admin
	$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin), (ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)
    
    Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock {

		#$computer = Get-ADComputer -Filter | Get-Random
		#$ComputerName = $computer.Name
		
		
        $ComputerAccount = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $using:Hostname | Select-Object -ExpandProperty UserName
        Set-ADComputer -Identity $ComputerAccount -ServicePrincipalName @{Add="HTTP/$ComputerAccount"}
	    Set-ADComputer -Identity $ComputerAccount -Add @{'msDS-AllowedToDelegateTo'="cifs/$using:Hostname.$using:Domain"}
	    Set-ADComputer -Identity $ComputerAccount -Add @{'msDS-AllowedToDelegateTo'="ldap/$using:Hostname.$using:Domain"}
	    Set-ADAccountControl -Identity "$ComputerAccount$" -TrustedToAuthForDelegation $true
      }


