param(
    [string]$hostname
)

Import-Module ".\scripts\utils\constants.ps1"
Import-Module "$($UTILS_PATH)config.ps1"


# Create credential object for the local admin and the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin),(ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)


Invoke-Command -ComputerName $Hostname -Credential $admin -ScriptBlock {
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
    $rdp = (Get-WmiObject -Class Win32_Group -Filter "LocalAccount=True and SID='S-1-5-32-555'").Name
    $users = Get-LocalUser
    $random_user = $users | Get-Random
    cmd /c net localgroup "$rdp" $random_user /add | Out-Null
}
