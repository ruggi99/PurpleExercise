function CreateService {
        param(
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$Hostname,

            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.PSCredential]$Credential
        )
	$commonWords = "Software", "System", "Utility", "Application", "Manager", "Tools", "Program"

	$randomFolderName = Get-Random -InputObject $commonWords
Write-Host $randomFolderName
	$randomSubFolderName1 = Get-Random -InputObject $commonWords
	$randomSubFolderName2 = Get-Random -InputObject $commonWords
	$randomSubFolderPath = "C:\$randomFolderName\$randomSubFolderName1 $randomSubFolderName1"
	$scriptPath = "$randomSubFolderPath\script.exe"

	$response = Invoke-Command -ComputerName $Hostname -Credential $Credential -ScriptBlock {
		New-Item -ItemType Directory -Path $using:randomSubFolderPath
		"This is a demo" | Out-File $using:scriptPath
	}

    Write-Host $randomFolderName
	return $randomFolderName
}