# Define configuration file path
$configPath = "AD_network.json"

# Check configuration file path	
if (-not (Test-Path -Path $configPath)) {
  	# Configuration file not found
  	throw "Configuration file not found. Check file path."  	
}

# Load configuration file
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json


# Create credential object for the local admin and the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin), (ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)


### START HERE

Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock { 
    # Get 3 groups from the groups_available list
    $groups_needed = 3
    $groups = [System.Collections.Generic.List[string]]@()

    $groups_available = [System.Collections.Generic.List[string]]@("marketing",
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

    for ($i = 0; $i -lt $groups_needed; $i=$i+1){
        # Get random group
        $existing_groups = Get-ADGroup -Filter * | Select Name
        $selected_group = Get-Random -InputObject $groups_available;
        # If not exist just create it
        $found = $false
        foreach ($g in $existing_groups) {
            if ($g.Name -eq $selected_group){
                $found = $true
                break
            }
        }
        if (-not $found){
            New-ADGroup -name $selected_group -GroupScope Global
        }
        $groups.Add($selected_group);
    }

    # Create BadACL
    $BadACL = @('GenericAll','GenericWrite','WriteOwner','WriteDACL','Self','WriteProperty');

    function VulnAD-AddACL {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$Destination,

            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [System.Security.Principal.IdentityReference]$Source,

            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$Rights

        )
        $ADObject = [ADSI]("LDAP://" + $Destination)
        $identity = $Source
        $adRights = [System.DirectoryServices.ActiveDirectoryRights]$Rights
        $type = [System.Security.AccessControl.AccessControlType] "Allow"
        $inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All"
        $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity,$adRights,$type,$inheritanceType
        $ADObject.psbase.ObjectSecurity.AddAccessRule($ACE)
        $ADObject.psbase.commitchanges()
    }

    # Create first BadACL
    $abuse = Get-Random -InputObject $BadACL
    $DstGroup = Get-ADGroup -Identity $groups[0]
    $SrcGroup = Get-ADGroup -Identity $groups[1]
    VulnAD-AddACL -Source $SrcGroup.sid -Destination $DstGroup.DistinguishedName -Rights $abuse
    Write-Host "BadACL $abuse $DstGroup to $SrcGroup"


    # Create second BadACL
    $abuse = Get-Random -InputObject $BadACL;
    $existing_users = Get-ADUser -Filter * | Select SamAccountName
    $randomuser = Get-Random -InputObject $existing_users
    $second_badacl_group = $groups[2]

    if ((Get-Random -Maximum 2)){
        $Dstobj = Get-ADUser -Identity $randomuser.SamAccountName
        $Srcobj = Get-ADGroup -Identity $second_badacl_group
    }else{
        $Srcobj = Get-ADUser -Identity $randomuser.SamAccountName
        $Dstobj = Get-ADGroup -Identity $second_badacl_group
    }
    VulnAD-AddACL -Source $Srcobj.sid -Destination $Dstobj.DistinguishedName -Rights $abuse 
    Write-Host "BadACL $abuse $($randomuser.SamAccountName) and $second_badacl_group"
}

