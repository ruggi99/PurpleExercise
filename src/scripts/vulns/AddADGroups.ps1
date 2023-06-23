
param(
    [string]$limit
       
)
    Import-Module ".\scripts\utils\constants.ps1"

    
    $Groups = [System.Collections.Generic.List[string]]@("marketing",
                                                         "sales",
                                                         "accounting",
                                                         "Office Admin",
                                                         "IT Admins",
                                                         "Executives",
                                                         "Senior management",
                                                         "Project management",
                                                         "Developers",
                                                         "Operations",
                                                         "Support",
                                                         "Finance",
                                                         "HumanResources",
                                                         "QA",
                                                         "HelpDesk",
                                                         "Architects",
                                                         "DBA",
                                                         "Auditors",
                                                         "Research",
                                                         "Backup");
   
    $existing_groups = Get-ADGroup -Filter * | Select Name



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

	# Create credential object for the local admin and the domain admin
	$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin), (ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)

    Import-Module "$($utils_path)Add-ADUser.ps1"
    
    Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock { 
	    for ($i = 0; $i -lt $using:limit; $i++){
            $found = $false
            $randomGroup = ""

            while (-not $found){
                $randomGroup = Get-Random -InputObject $using:Groups
                if ($randomGroup -notin $existing_groups){
                    $found = $true
                }
            }
            New-ADGroup -name $randomGroup -GroupScope Global
            $Groups.Remove($randomGroup);


            for ($j=1; $j -lt (Get-Random -Maximum 20); $j=$j+1 ) {
                $randomuser, $password = AddAdUser
                #Write-Host "Adding $randomuser to $randomGroup with password $password"
                Add-ADGroupMember -Identity $randomGroup -Members $randomuser
            }
        }
    }