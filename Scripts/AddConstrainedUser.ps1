
param(
    [string]$Hostname,
    [string]$limit
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
	$Domain = $config.domain.name

	# Define users limit
	$UsersLimit = $config.domain.usersLimit

	# Create credential object for the local admin and the domain admin
	$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin), (ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)
    
    Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock {
      Add-Type -AssemblyName System.Web
      for ($i=1; $i -le $limit; $i=$i+1 ) {
        $firstname = (VulnAD-GetRandom -InputList HumansNames);
        $lastname = (VulnAD-GetRandom -InputList HumansNames);
        $fullname = "{0} {1}" -f ($firstname , $lastname);
        $SamAccountName = ("{0}.{1}" -f ($firstname, $lastname)).ToLower();
        $principalname = "{0}.{1}" -f ($firstname, $lastname);
        $generated_password = ([System.Web.Security.Membership]::GeneratePassword(12,2))
        Write-Info "Creating $SamAccountName User"
        Try { New-ADUser -Name "$firstname $lastname" -GivenName $firstname -Surname $lastname -SamAccountName $SamAccountName -UserPrincipalName $principalname@$Global:Domain -AccountPassword (ConvertTo-SecureString $generated_password -AsPlainText -Force) -PassThru | Enable-ADAccount } Catch {}
        
        

        $User= $SamAccountName


		$computer = Get-ADComputer -Filter | Get-Random
		$ComputerName = $computer.Name
		
        #user can be replaced with SamAccountNAme
        Set-ADUser -Identity $User -ServicePrincipalName @{Add="HTTP/$User"}
	    Get-ADUser -Identity $User | Set-ADObject -Add @{'msDS-AllowedToDelegateTo'="cifs/$ComputerName"}
	    Get-ADUser -Identity $User | Set-ADObject -Add @{'msDS-AllowedToDelegateTo'="cifs/$($ComputerName).$($using:Domain)"}
	    Set-ADAccountControl -Identity $User -TrustedToAuthForDelegation $true
    
      }


}