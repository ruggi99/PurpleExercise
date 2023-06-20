param(
    [string]$Hostname
)

Import-Module "Utils\CreateService.ps1"

# Define configuration file path
$configPath = "AD_network.json"

# Check configuration file path
if (-not (Test-Path -Path $configPath)) {
    # Configuration file not found
    throw "Configuration file not found. Check file path."
}

# Load configuration file
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# Define the domain name
$Domain = $config.domain.name

# Define users limit
$UsersLimit = $config.domain.usersLimit

# Create credential object for the local admin and the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin), (ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)

$ServiceName,$scriptPath = CreateService -Credential $admin -Hostname $Hostname

Invoke-Command -ComputerName $Hostname -Credential $admin -ScriptBlock {
    icacls $using:scriptPath /grant *DA:F /inheritance:r /t | Out-Null
    cmd /c sc create $using:ServiceName binpath= "$using:scriptPath" type= own type= interact error= ignore start= auto | Out-Null
}
.\subinacl.exe /SERVICE \\$Hostname\usosvc /GRANT=EVERYONE=F | Out-Null
.\subinacl.exe /SERVICE \\$Hostname\$ServiceName /GRANT=EVERYONE=F | Out-Null

