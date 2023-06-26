param (
    [string]$limit
)


Import-Module ".\scripts\utils\constants.ps1"
Import-Module "$($UTILS_PATH)Add-ADUser.ps1"
Import-Module "$($UTILS_PATH)config.ps1"


# Create credential object for the local admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin), (ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)


# Generate accounts
$accounts = [System.Collections.Generic.List[string]]@()
for ($i=0; $i -lt $limit; $i=$i+1 ) {
    $password = Get-Random -InputObject $BAD_PASSWORDS;
    $sam_account_name, $_ = AddADUser -password $password
    $accounts.Add($sam_account_name)
}

# Add new kerberoastable users 
Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock {
    foreach($account in $using:accounts){
        $selected_spn = (Get-Random -InputObject $using:SPNS)
        setspn $using:SamAccountName -s $selected_spn | Out-Null
    }

}