param(
    [string]$hostname
)

Import-Module -force ".\scripts\utils\constants.ps1"
Import-Module -force "$($UTILS_PATH)config.ps1"


# Create credential object for the local admin and the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin),(ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)

Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock {
    $computers = Get-ADComputer -Filter * | Select-Object SamAccountName
    $computer_account = (Get-Random -InputObject $computers).SamAccountName
    Set-ADComputer -Identity $computer_account -ServicePrincipalName @{ Add = "HTTP/$computer_account" }
    Set-ADComputer -Identity $computer_account -Add @{ 'msDS-AllowedToDelegateTo' = "cifs/$using:hostname.$using:config.domain.name" }
    Set-ADComputer -Identity $computer_account -Add @{ 'msDS-AllowedToDelegateTo' = "ldap/$using:hostname.$using:config.domain.name" }
    Set-ADAccountControl -Identity "$computer_account" -TrustedToAuthForDelegation $true
}
