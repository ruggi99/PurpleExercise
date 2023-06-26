param(
    [string]$hostname
)

Import-Module ".\scripts\utils\constants.ps1"
Import-Module "$($UTILS_PATH)config.ps1"
Import-Module "$($UTILS_PATH)Add-ADUser.ps1"


# Create credential object for the local admin and the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin),(ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)

$sam_account_name,$password = AddADUser

Invoke-Command -ComputerName $Hostname -Credential $admin -ScriptBlock {
    cmd /c net localgroup "Administrators" $using:sam_account_name /add | Out-Null
}


