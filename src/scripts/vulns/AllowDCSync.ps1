

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
		
	$allUsers = Get-ADUser -Filter * | Select-Object SamAccountName

	# Get a random user from the list
	$randomUser = (Get-Random -InputObject $allUsers).SamAccountName

	$ADObject = [ADSI]("LDAP://" + (Get-ADDomain $using:Domain).DistinguishedName)
	$sid = (Get-ADUser -Identity $randomUser).sid

	$objectGuidGetChanges = New-Object Guid 1131f6aa-9c07-11d1-f79f-00c04fc2dcd2
	$ACEGetChanges = New-Object DirectoryServices.ActiveDirectoryAccessRule($sid,'ExtendedRight','Allow',$objectGuidGetChanges)
	$ADObject.psbase.Get_objectsecurity().AddAccessRule($ACEGetChanges)

	$objectGuidGetChanges = New-Object Guid 1131f6ad-9c07-11d1-f79f-00c04fc2dcd2
	$ACEGetChanges = New-Object DirectoryServices.ActiveDirectoryAccessRule($sid,'ExtendedRight','Allow',$objectGuidGetChanges)
	$ADObject.psbase.Get_objectsecurity().AddAccessRule($ACEGetChanges)

	$objectGuidGetChanges = New-Object Guid 89e95b76-444d-4c62-991a-0facbeda640c
	$ACEGetChanges = New-Object DirectoryServices.ActiveDirectoryAccessRule($sid,'ExtendedRight','Allow',$objectGuidGetChanges)
	$ADObject.psbase.Get_objectsecurity().AddAccessRule($ACEGetChanges)
	$ADObject.psbase.CommitChanges()
}