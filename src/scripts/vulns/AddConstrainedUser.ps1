param(
    [string]$limit
)

Import-Module ".\scripts\utils\constants.ps1"
Import-Module "$($UTILS_PATH)Add-ADUser.ps1"
Import-Module "$($UTILS_PATH)config.ps1"

# Create credential object for the local admin and the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin),(ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)

# Generate accounts
$accounts = [System.Collections.Generic.List[string]]@()
for ($i = 1; $i -lt $limit; $i++) {
    $sam_account_name,$_ = AddADUser
    $accounts.Add($sam_account_name)
}

# Add vuln
Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock {
    foreach ($account in $using:accounts) {
        $computer = Get-ADComputer -Filter * | Get-Random

        Set-ADUser -Identity $account -ServicePrincipalName @{ Add = "HTTP/$account" }
        Get-ADUser -Identity $account | Set-ADObject -Add @{ 'msDS-AllowedToDelegateTo' = "cifs/$computer.Name" }
        Get-ADUser -Identity $account | Set-ADObject -Add @{ 'msDS-AllowedToDelegateTo' = "cifs/$($computer.Name).$($using:config.domain.name)" }
        Set-ADAccountControl -Identity $account -TrustedToAuthForDelegation $true
    }
}
