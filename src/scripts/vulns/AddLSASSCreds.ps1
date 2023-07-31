param(
    [string]$hostname,
    [boolean]$add
)

Import-Module -force ".\scripts\utils\constants.ps1"
Import-Module -force "$($UTILS_PATH)config.ps1"
Import-Module -force "$($UTILS_PATH)Add-ADUser.ps1"


# Create credential object for the local admin and the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList "$($config.domain.admin)@$($config.domain.name)",(ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)

if ($add -eq $true) {
    $username, $password = AddADUser
} else {
    $json_users = Get-Content -Path $USERS_PATH -Raw | ConvertFrom-Json
    $keys = $json_users.PSObject.Properties | Select-Object -ExpandProperty Name
    $username = $keys | Get-Random
    $password = $json_users.$username
}

if (Get-Random -Maximum 2) {
    Invoke-Command -ComputerName $hostname -Credential $admin -ScriptBlock {
        #$groupsid = (Get-WMIObject -Class Win32_Group -Filter "LocalAccount=True and SID='S-1-5-domain-500'").Name
        cmd /c net localgroup "Administrators" $using:username /add | Out-String
    }
} else {
    Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock {
        #$groupsid = (Get-WMIObject -Class Win32_Group -Filter "LocalAccount=True and SID='S-1-5-domain-512'").Name
        Add-ADGroupMember -Identity "Domain Admins" -Members $using:username
    }
}

$task_name = Get-Random -InputObject $TASK_NAMES


Invoke-Command -ComputerName $hostname -Credential $admin -ScriptBlock {
    schtasks /create /sc minute /mo 10 /tn $using:task_name /tr calc.exe /ru $($using:username) /rp $($using:password) /f
    schtasks /run /tn "$using:task_name"
}

