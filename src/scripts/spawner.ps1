param(
    [string]$limit
)

Import-Module ".\scripts\utils\constants.ps1"

# Define configuration file path
$configPath = "AD_network.json"

# Check configuration file path
if (-not (Test-Path -Path $configPath)) {
    # Configuration file not found
    throw "Configuration file not found. Check file path."
}

# Load configuration file
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# Create credential object for the local admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin),(ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)

# Define the domain name
$Domain = $config.domain.name

$assets = Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock { Get-ADComputer -Filter * -Property Name | Select-Object -ExpandProperty Name }

for ($i = 0; $i -lt $limit; $i = $i + 1) {
    $random_asset = Get-Random -InputObject $assets
    $scripts = Get-ChildItem $vulns_path | Select-Object -ExpandProperty Name
    $random_script = Get-Random -InputObject $scripts
    $n = Get-Random -Maximum 10

    if ( -not (Test-Path -Path $USERS_PATH) ) {
        $bool = $true
    } else {
        $bool = @($true, $false) | Get-Random
    }

    Write-Host "Executing $random_script"

    Try {& "$($vulns_path)$($random_script)" -limit $n -hostname "$($random_asset).$($domain)" -add $bool} Catch {continue}
}

return 0
