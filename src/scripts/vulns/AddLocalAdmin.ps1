param(
    [string]$hostname,
    [boolean]$add
)

Import-Module -force ".\scripts\utils\constants.ps1"
Import-Module -force "$($UTILS_PATH)config.ps1"
Import-Module -force "$($UTILS_PATH)Add-ADUser.ps1"


# Create credential object for the local admin and the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin),(ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)

if ($add -eq $true) {
    $sam_account_name, $_ = AddADUser
} else {
    $json_users = Get-Content -Path $USERS_PATH -Raw | ConvertFrom-Json
    $keys = $json_users.PSObject.Properties | Select-Object -ExpandProperty Name
    $sam_account_name = $keys | Get-Random
}

Invoke-Command -ComputerName $Hostname -Credential $admin -ScriptBlock {
    cmd /c net localgroup "Administrators" $using:sam_account_name /add | Out-Null
}


