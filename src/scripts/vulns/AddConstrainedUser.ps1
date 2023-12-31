param(
    [string]$limit,
    [boolean]$add
)

Import-Module -force ".\scripts\utils\constants.ps1"
Import-Module -force "$($UTILS_PATH)Add-ADUser.ps1"
Import-Module -force "$($UTILS_PATH)config.ps1"

# Create credential object for the local admin and the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList "$($config.domain.admin)@$($config.domain.name)",(ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)

# Generate accounts
$accounts = [System.Collections.Generic.List[string]]@()
for ($i=1; $i -lt $limit; $i++) {
    if ($add -eq $true) {
        $username, $password = AddADUser
    } else {
        $json_users = Get-Content -Path $USERS_PATH -Raw | ConvertFrom-Json
        $keys = $json_users.PSObject.Properties | Select-Object -ExpandProperty Name
        $username = $keys | Get-Random
    }
    $accounts.Add($username)
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
