param(
    [string]$hostname,
    [string]$limit
)

Import-Module -force ".\scripts\utils\constants.ps1"
Import-Module -force "$($UTILS_PATH)config.ps1"


# Create credential object for the local admin and the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin),(ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)


Invoke-Command -ComputerName $hostname -Credential $admin -ScriptBlock {
    for ($i = 0; $i -le $using:limit; $i++)
    {
        $random_path = Get-Random -InputObject $using:EXCLUSION_PATHS
        New-Item -Path $random_path -ItemType Directory | Out-Null
        Add-MpPreference -ExclusionPath $random_path
    }
}
