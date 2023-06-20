param(
    [string]$Hostname,
    [string]$limit
)

	
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
	$Global:Domain = $config.domain.name

	# Define users limit
	$UsersLimit = $config.domain.usersLimit

	# Create credential object for the local admin and the domain admin
	$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin), (ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)


    Invoke-Command -ComputerName $Hostname -Credential $admin -ScriptBlock { 

    	Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
    	$rdp = (Get-WMIObject -Class Win32_Group -Filter "LocalAccount=True and SID='S-1-5-32-555'").Name
        $users = Get-LocalUser
        $randomUser = $users | Get-Random
    	cmd /c net localgroup "$rdp" $randomUser /add | Out-Null
    }
       



