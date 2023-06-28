param(
    [string]$limit = 1

)

Import-Module -force ".\scripts\utils\constants.ps1"
Import-Module -force "$($UTILS_PATH)config.ps1"
Import-Module -force "$($UTILS_PATH)Add-ADUser.ps1"


# Create credential object for the local admin and the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin),(ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)


$DEFAULT_PASSWORD = "Changeme123!";

# Generate accounts
$accounts = [System.Collections.Generic.List[string]]@()
for ($i = 0; $i -lt $limit; $i++) {
    $sam_account_name,$_ = AddADUser -password $DEFAULT_PASSWORD
    $accounts.Add($sam_account_name)
}

# Set default password
Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock {
    foreach ($account in $using:accounts) {
        Set-ADUser $account -Description "New User, DefaultPassword"
    }
}

