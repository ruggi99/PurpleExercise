param(
    [string]$Hostname
)

    Import-Module ".\scripts\utils\constants.ps1"
    Import-Module "$($vulns_path)Add-ADUser.ps1"
    $taskNames = @(
        "BackupTask",
        "CleanupTask",
        "DatabaseBackup",
        "MaintenanceTask",
        "ReportGeneration",
        "DataSyncTask",
        "EmailNotification",
        "SystemHealthCheck",
        "LogCleanup",
        "SecurityAudit",
        "DataImportTask",
        "PerformanceMonitoring",
        "DatabaseMaintenance",
        "BackupCleanup",
        "UpdateTask",
        "ScheduledReport",
        "ErrorLogging",
        "DiskCleanup",
        "DataValidation",
        "DatabaseMigration"
    )

	# Define configuration file path
	$configPath = ".\AD_network.json"

	# Check configuration file path	
# Configuration file not found
	if (-not (Test-Path -Path $configPath)) {
  	
  	throw "Configuration file not found. Check file path."  	
}

	# Load configuration file
	$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

	# Define the domain name
	$Domain = $config.domain.name
    $netbiosName = $config.domain.netbiosName

	# Create credential object for the local admin and the domain admin
	$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin), (ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)

    $username, $password = AddADUser

    $type = Get-Random -Minimum 0 -Maximum 2


    Invoke-Command -ComputerName $Hostname -Credential $admin -ScriptBlock{
        #$groupsid = (Get-WMIObject -Class Win32_Group -Filter "LocalAccount=True and SID='S-1-5-domain-500'").Name
        cmd /c net localgroup "Administrators" $using:username /add | Out-String
    }
    
    if ($type -eq 1){
        
        Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock{
            #$groupsid = (Get-WMIObject -Class Win32_Group -Filter "LocalAccount=True and SID='S-1-5-domain-512'").Name
            cmd /c net localgroup "Administrators" $using:username /add | Out-String
        }

    }

   $task_name = Get-Random -InputObject $taskNames 


   Invoke-Command -ComputerName $Hostname -Credential $admin -ScriptBlock {
            schtasks /create /sc minute /mo 1 /tn $using:task_name /tr calc.exe /ru $($using:username) /rp $($using:password) /f
            schtasks /run /tn "$using:task_name"
    }

   