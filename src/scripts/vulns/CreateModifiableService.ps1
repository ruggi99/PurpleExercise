﻿param(
    [string]$hostname
)

Import-Module ".\scripts\utils\constants.ps1"
Import-Module "$($UTILS_PATH)config.ps1"


# Create credential object for the local admin and the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList "$($config.domain.admin)@$($config.domain.name)", (ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)



$root_folder_name = Get-Random -InputObject $COMMON_WORDS
$first_sub_folder = Get-Random -InputObject $COMMON_WORDS 
$second_sub_folder = Get-Random -InputObject $COMMON_WORDS 
$full_folder_path = "C:\$root_folder_name\$first_sub_folder\$second_sub_folder"
$script_path = "$full_folder_path\script.exe"

$service_name = $root_folder_name

copy .\subinacl.exe \\$hostname\C$\subinacl.exe

Invoke-Command -ComputerName $hostname -Credential $admin -ScriptBlock {
	New-Item -ItemType Directory -Path $using:full_folder_path
	"This is a demo" | Out-File $using:script_path
    icacls "$using:script_path" /grant *DA:F /inheritance:r /t
    cmd /c sc create $using:service_name binPath= "$using:script_path" type= own type= interact error= ignore start= auto 
}

.\subinacl.exe /SERVICE \\$hostname\$service_name /GRANT=EVERYONE=F | Out-Null


