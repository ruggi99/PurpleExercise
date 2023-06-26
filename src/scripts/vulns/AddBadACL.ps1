Import-Module ".\scripts\utils\constants.ps1"
Import-Module "$($UTILS_PATH)config.ps1"


# Create credential object for the local admin and the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin),(ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)


### START HERE

Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock {
    # Get 3 groups from the groups_available list
    $groups_needed = 3
    $groups = [System.Collections.Generic.List[string]]@()

    $groups_available = [System.Collections.Generic.List[string]]@();
    foreach ($group in $using:GROUPS_AVAILABLE) {
        $groups_available.Add($group)
    }

    for ($i = 0; $i -lt $groups_needed; $i = $i + 1) {
        # Get random group
        $existing_groups = Get-ADGroup -Filter * | Select-Object Name
        $selected_group = Get-Random -InputObject $groups_available;
        # If not exist just create it
        $found = $false
        foreach ($g in $existing_groups) {
            if ($g.Name -eq $selected_group) {
                $found = $true
                break
            }
        }
        if (-not $found) {
            New-ADGroup -Name $selected_group -GroupScope Global
        }
        $groups.Add($selected_group);
    }

    # Create BadACL
    function VulnAD-AddACL {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]$Destination,

            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [System.Security.Principal.IdentityReference]$Source,

            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]$Rights

        )
        $ADObject = [adsi]("LDAP://" + $Destination)
        $identity = $Source
        $adRights = [System.DirectoryServices.ActiveDirectoryRights]$Rights
        $type = [System.Security.AccessControl.AccessControlType]"Allow"
        $inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]"All"
        $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity,$adRights,$type,$inheritanceType
        $ADObject.psbase.ObjectSecurity.AddAccessRule($ACE)
        $ADObject.psbase.commitchanges()
    }

    # Create first BadACL
    $abuse = Get-Random -InputObject $using:BAD_ACL
    $dst_group = Get-ADGroup -Identity $groups[0]
    $src_group = Get-ADGroup -Identity $groups[1]
    VulnAD-AddACL -Source $src_group.sid -Destination $dst_group.DistinguishedName -Rights $abuse
    Write-Host "BadACL $abuse $dst_group to $src_group"


    # Create second BadACL
    $abuse = Get-Random -InputObject $using:BAD_ACL;
    $existing_users = Get-ADUser -Filter * | Select-Object SamAccountName
    $random_user = Get-Random -InputObject $existing_users
    $second_badacl_group = $groups[2]

    if ((Get-Random -Maximum 2)) {
        $dst_obj = Get-ADUser -Identity $random_user.SamAccountName
        $src_obj = Get-ADGroup -Identity $second_badacl_group
    } else {
        $src_obj = Get-ADUser -Identity $random_user.SamAccountName
        $dst_obj = Get-ADGroup -Identity $second_badacl_group
    }
    VulnAD-AddACL -Source $src_obj.sid -Destination $dst_obj.DistinguishedName -Rights $abuse
    Write-Host "BadACL $abuse $($random_user.SamAccountName) and $second_badacl_group"
}

