Import-Module ".\scripts\utils\constants.ps1"

# Check configuration file path	
if (-not (Test-Path -Path $config_path)) {
    # Configuration file not found
    throw "Configuration file not found. Check file path."
}	

# Load configuration file
$config = Get-Content -Path $config_path -Raw | ConvertFrom-Json