param(
    [string]$Hostnames
)

    Import-Module ".\Add-ADUser.ps1"
	# AD INITIALIZATION
	# Define configuration file path
	$configPath = ".\AD_network.json"

	# Check configuration file path	
# Configuration file not found
	if (-not (Test-Path -Path $configPath)) {
  	
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


    $assets = Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock { Get-ADComputer -Filter * -Property Name | Select-Object -ExpandProperty Name }

    $random_asset = Get-Random -InputObject $assets

    # valutare se l'asset scelto è proprio il DC, in tal caso type deve essere 1
    $type = Get-Random -Minimum 0 -Maximum 3


    #query DC da DNSHostName
    $isDomainController = Get-ADDomainController -Discover -DomainName $random_asset.DNSHostName

    Write-Host $random_asset
    #compara gli oggetti
    if($random_asset -eq $isDomainController)
    {
        $type=1;
        Write-Host "is DC"
    }
    else
    {
        Write-Host "not DC"
    }

    $username, $password = AddADUser
    
    switch($type){
        0{
            Invoke-Command -ComputerName $Hostname -Credential $admin -ScriptBlock{
                #$groupsid = (Get-WMIObject -Class Win32_Group -Filter "LocalAccount=True and SID='S-1-5-domain-500'").Name
                cmd /c net localgroup "Administrators" $using:username /add | Out-String
            }
        }
        1{
            Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock{
                #$groupsid = (Get-WMIObject -Class Win32_Group -Filter "LocalAccount=True and SID='S-1-5-domain-512'").Name
                cmd /c net localgroup "Administrators" $using:username /add | Out-String
            }
        }

    }

    Invoke-Command -ComputerName $Hostname -Credential $admin -ScriptBlock {
    	    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
    	    $rdp = (Get-WMIObject -Class Win32_Group -Filter "LocalAccount=True and SID='S-1-5-32-555'").Name
            cmd /c net localgroup "$rdp" $using:username /add | Out-Null

    }

   $user_cred = New-Object System.Management.Automation.PSCredential -ArgumentList $username, (ConvertTo-SecureString -String $password -AsPlainText -Force)


   Invoke-Command -ComputerName "$($random_asset).$($domain)" -Credential $user_cred -ScriptBlock {


            $path = "HKLM:\SOFTWARE\Microsoft\Terminal Server Client" 
            $key = "AuthenticationLevelOverride" 
            $value = 0 
            New-ItemProperty -Path $path -Name $key -Value $value -PropertyType DWORD -Force | Out-Null

            cmdkey /generic:$using:Hostname /user:$using:username /pass:$using:password

            Start-Process -FilePath "mstsc.exe" -ArgumentList "/v:$using:Hostname /noConsentPrompt" -WindowStyle "Hidden"

    }
