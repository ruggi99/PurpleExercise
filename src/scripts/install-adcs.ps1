Import-Module -force ".\scripts\utils\constants.ps1"
Import-Module -force "$($UTILS_PATH)config.ps1"

function Write-Good { param($String) Write-Host $Global:PlusLine $String -ForegroundColor 'Green' }
function Write-Bad  { param($String) Write-Host $Global:ErrorLine $String -ForegroundColor 'red' }
function Write-Info { param($String) Write-Host $Global:InfoLine $String -ForegroundColor 'gray' }

# Create credential object for the local admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin),(ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)

# Install minimum ADCS
Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock {
    Install-WindowsFeature Adcs-Cert-Authority
    Install-AdcsCertificationAuthority -Force
    Add-WindowsFeature Adcs-Web-Enrollment
    Install-AdcsWebEnrollment -Force
}