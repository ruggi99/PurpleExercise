param(
    [string]$limit

)

Import-Module -force ".\scripts\utils\constants.ps1"
Import-Module -force "$($UTILS_PATH)config.ps1"
Import-Module -force "$($UTILS_PATH)Add-ADUser.ps1"

# Create credential object for the local admin and the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList "$($config.domain.admin)@$($config.domain.name)",(ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)


# Generate accounts
$accounts = [System.Collections.Generic.List[string]]@()
for ($i = 0; $i -lt $limit; $i++) {
    $name_and_passwd = AddADUser
    $accounts.Add($name_and_passwd)
}

# Set password in obj description
Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock {
    foreach ($account in $using:accounts) {
        Set-ADUser $using:name_and_passwd[0] -Description "User Password $using:name_and_passwd[1]"
    }
}
