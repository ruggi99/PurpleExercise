param(
    [string]$limit
       
)
    $Groups = @('marketing','sales','accounting');

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

    Import-Module ".\Utils\Add-ADUser.ps1"
    
    Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock { 
	    for ($i = 0; $i -le $using:limit; $i++){
            $randomGroup = Get-Random -InputObject $using:Groups
            Try { New-ADGroup -name $randomGroup } Catch {}
            for ($i=1; $i -le (Get-Random -Maximum 20); $i=$i+1 ) {
                $randomuser = AddAdUser
                Write-Host "Adding $randomuser to $randomGroup"
                Try { Add-ADGroupMember -Identity $randomGroup -Members $randomuser } Catch {}
            }
        }
    }


