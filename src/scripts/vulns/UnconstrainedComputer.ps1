param(
    [string]$hostname
)

Import-Module ".\scripts\utils\constants.ps1"
Import-Module "$($UTILS_PATH)config.ps1"


# Create credential object for the local admin and the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin),(ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)


Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock {

    $computer_account = (Get-ADComputer -Filter { DNSHostName -EQ $using:hostname }).SamAccountName

    Get-ADComputer -Identity $computer_account | Set-ADAccountControl -TrustedForDelegation $true
}
