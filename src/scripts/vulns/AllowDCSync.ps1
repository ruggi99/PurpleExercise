Import-Module -force ".\scripts\utils\constants.ps1"
Import-Module -force "$($UTILS_PATH)config.ps1"


# Create credential object for the local admin and the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList "$($config.domain.admin)@$($config.domain.name)",(ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)

Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock {

    $all_users = Get-ADUser -Filter * | Select-Object SamAccountName

    # Get a random user from the list
    $random_user = (Get-Random -InputObject $all_users).SamAccountName

    $ADO_object = [adsi]("LDAP://" + (Get-ADDomain $using:config.domain.Name).DistinguishedName)
    $sid = (Get-ADUser -Identity $random_user).sid

    $object_guid_get_changes = New-Object Guid 1131f6aa-9c07-11d1-f79f-00c04fc2dcd2
    $ACE_get_changes = New-Object DirectoryServices.ActiveDirectoryAccessRule ($sid,'ExtendedRight','Allow',$object_guid_get_changes)
    $ADO_object.psbase.Get_objectsecurity().AddAccessRule($ACE_get_changes)

    $object_guid_get_changes = New-Object Guid 1131f6ad-9c07-11d1-f79f-00c04fc2dcd2
    $ACE_get_changes = New-Object DirectoryServices.ActiveDirectoryAccessRule ($sid,'ExtendedRight','Allow',$object_guid_get_changes)
    $ADO_object.psbase.Get_objectsecurity().AddAccessRule($ACE_get_changes)

    $object_guid_get_changes = New-Object Guid 89e95b76-444d-4c62-991a-0facbeda640c
    $ACE_get_changes = New-Object DirectoryServices.ActiveDirectoryAccessRule ($sid,'ExtendedRight','Allow',$object_guid_get_changes)
    $ADO_object.psbase.Get_objectsecurity().AddAccessRule($ACE_get_changes)
    $ADO_object.psbase.commitchanges()
}
