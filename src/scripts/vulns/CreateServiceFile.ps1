param(
    [string]$Hostname
)

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

# Create credential object for the local admin and the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin), (ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)

$commonWords = "Software", "System", "Utility", "Application", "Manager", "Tools", "Program"

$randomFolderName = Get-Random -InputObject $commonWords
$randomSubFolderName1 = Get-Random -InputObject $commonWords 
$randomSubFolderName2 = Get-Random -InputObject $commonWords 
$randomSubFolderPath = "C:\$randomFolderName\$randomSubFolderName1 $randomSubFolderName1"
$scriptPath = "$randomSubFolderPath\script.exe"
$ServiceName = $randomFolderName

Invoke-Command -ComputerName $Hostname -Credential $admin -ScriptBlock {
	New-Item -ItemType Directory -Path $using:randomSubFolderPath
	"This is a demo" | Out-File $using:scriptPath
    icacls $using:scriptPath /grant BUILTIN\Users:W | Out-Null
    cmd /c sc create $using:ServiceName binpath= "$using:scriptPath" type= own type= interact error= ignore start= auto | Out-Null
}
.\subinacl.exe /SERVICE \\$Hostname\$ServiceName /GRANT=EVERYONE=PTO | Out-Null

