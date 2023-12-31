Import-Module -force ".\scripts\utils\constants.ps1"
Import-Module -force "$($UTILS_PATH)config.ps1"
Import-Module -force "$($UTILS_PATH)Add-ADUser.ps1"

function Write-Good { param($String) Write-Host $Global:PlusLine $String -ForegroundColor 'Green' }
function Write-Bad  { param($String) Write-Host $Global:ErrorLine $String -ForegroundColor 'red' }
function Write-Info { param($String) Write-Host $Global:InfoLine $String -ForegroundColor 'gray' }

# Define the domain name
$Domain = $config.domain.name

# Create credential object for the local admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin),(ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)

# Test asset availability using local admin creds 
do {
    $repeat = $false;
    $err = Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock { whoami }
    if ($err -eq $null) {
        $repeat = $true
        Write-Bad "$($config.domain.hostname) ($($config.domain.dcip)) test connection failed"
    } else {
        Write-Good "$($config.domain.hostname) ($($config.domain.dcip)) test connection passed"
    }
} while ($repeat)

Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock {
    Set-TimeZone -ID "W. Europe Standard Time"
}

$installState = $(Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock { (Get-WindowsFeature -Name "AD-domain-services").InstallState }).value

if ($installState -eq "Installed") {
    # Active Directory is already installed
    Write-Output "Active Directory has been already installed on domain."
} else {
    # Active Directory is not installed
    Write-Info "Active Directory is not installed yet on domain."

    $dc_hostname = Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock { HOSTNAME }

    if ($dc_hostname -ne $config.domain.hostname) {

        # Da eseguire nel dc
        Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock {
            Rename-Computer -NewName $using:config.domain.hostname -Restart -Force
        }
        Write-Good "Domain controller hostname renamed."
        Write-Info "Waiting after DC restarts"
        cmd /c pause

        # if you didn't install Active Directory yet, you can try
        # Da eseguire nel dc
        Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock {
            Install-WindowsFeature AD-domain-services
            Import-Module -force ADDSDeployment
		    Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "C:\\Windows\\NTDS" -DomainMode "7" -DomainName $using:config.domain.name -DomainNetbiosName $using:config.domain.netbiosName -ForestMode "7" -InstallDns:$true -LogPath "C:\\Windows\\NTDS" -NoRebootOnCompletion:$false -SysvolPath "C:\\Windows\\SYSVOL" -SafeModeAdministratorPassword (ConvertTo-SecureString "$using:config.domain.password" -AsPlainText -Force) -Force:$true
        }
        Write-Good "Active Directory installed on DC."
        Write-Info "Waiting after DC restarts"
        cmd /c pause
    }
}

# Set DNS Forwarder to DC
Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock {
    Add-DnsServerForwarder -IPAddress 1.1.1.1 -Passthru | Out-Null
    Set-ADDefaultDomainPasswordPolicy -Identity $using:Domain -LockoutDuration 00:01:00 -LockoutObservationWindow 00:01:00 -ComplexityEnabled $false -ReversibleEncryptionEnabled $False -MinPasswordLength 4
}

$networkInterface = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
Set-DnsClientServerAddress -InterfaceIndex $networkInterface.interfaceIndex -ServerAddresses $config.domain.dcip | Out-Null

# Test asset availability using local admin creds
foreach ($asset in $config.assets) {
    # Create credential object for the asset admin
    $creds = New-Object System.Management.Automation.PSCredential -ArgumentList $asset.username,(ConvertTo-SecureString -String $asset.password -AsPlainText -Force)

    do {
        $repeat = $false;
        $err = Invoke-Command -ComputerName $asset.ip -Credential $creds -ScriptBlock { whoami }
        if ($err -eq $null) {
            $repeat = $true
            Write-Bad "$($asset.hostname) ($($asset.ip)) test connection failed"
        } else {
            Write-Good "$($asset.hostname) ($($asset.ip)) test connection passed"
        }
    } while ($repeat)
}

# Create credential object for the domain admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList "$($config.domain.admin)@$($config.domain.name)",(ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)

# Attempt to join for each asset
foreach ($asset in $config.assets) {
    # Create credential object for the asset admin
    $creds = New-Object System.Management.Automation.PSCredential -ArgumentList $asset.username,(ConvertTo-SecureString -String $asset.password -AsPlainText -Force)

    # Make domain join
    Invoke-Command -ComputerName $asset.ip -Credential $creds -ScriptBlock {
        Set-TimeZone -ID "W. Europe Standard Time"

        netsh advfirewall set allprofiles state off | Out-Null
        $eth = Get-NetAdapter -Name * | Where-Object { $_.Status -eq 'Up' } | Format-Table Name -HideTableHeaders | Out-String
        Set-DnsClientServerAddress -InterfaceAlias $eth.Trim() -ServerAddresses ($using:config.domain.dcip)
        Add-Computer -DomainName $using:config.domain.name -Credential $using:admin   
    }

    Try {
        Rename-Computer -ComputerName $asset.ip -NewName $asset.hostname -DomainCredential $admin -Restart -Force -ErrorAction Stop
    } Catch {
        Restart-Computer -ComputerName $asset.ip -Credential $creds -Force
    }

    if ($errmsg.Count -gt 0) {
        Write-Bad "Asset $($asset.hostname) not added to domain $($Global:Domain)"
    } else {
        Write-Good "Asset $($asset.hostname) added to domain $($Global:Domain)"
    }
}

Write-Info "Waiting after VM restarts"
cmd /c pause

rm $USERS_PATH -ErrorAction Ignore

# Create a set of users
for ($i = 0; $i -lt 9; $i++) {
    switch(Get-Random -Maximum 3) {
        0 { .\scripts\vulns\AddUserDefaultPassword.ps1 -limit 1 }
        1 { .\scripts\vulns\AddUserPwdInObjectDescription.ps1 -limit 1 }
        2 { AddAdUser }
    }
}

# Create user with RDP rights. No default password and no password in description
$random_user, $password = AddAdUser

$labConfig = Get-Content -Path $LAB_CONFIG_PATH -Raw | ConvertFrom-Json
$labConfig.lab.user_credentials.user = $random_user
$labConfig.lab.user_credentials.password = $password
$labConfig | ConvertTo-Json | Out-File -Encoding utf8 $LAB_CONFIG_PATH

# Test asset availability using local admin creds
foreach ($asset in $config.assets) {
    # Create credential object for the asset admin
    $local_admin = New-Object System.Management.Automation.PSCredential -ArgumentList "$($asset.username)",(ConvertTo-SecureString -String $asset.password -AsPlainText -Force)

    do {
        $repeat = $false;
        $err = Invoke-Command -ComputerName $asset.ip -Credential $local_admin -ScriptBlock { whoami }
        if ($err -eq $null) {
            $repeat = $true
            Write-Bad "$($asset.hostname) ($($asset.ip)) test connection failed"
        } else {
            Write-Good "$($asset.hostname) ($($asset.ip)) test connection passed"
        }
    } while ($repeat)
}


foreach ($asset in $config.assets) {
    # Create credential object for the local admin
    $local_admin = New-Object System.Management.Automation.PSCredential -ArgumentList "$($asset.username)",(ConvertTo-SecureString -String $asset.password -AsPlainText -Force)

    Invoke-Command -ComputerName $asset.ip -Credential $local_admin -ScriptBlock {
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
        $rdp = (Get-WMIObject -Class Win32_Group -Filter "LocalAccount=True and SID='S-1-5-32-555'").Name
        cmd /c net localgroup "$rdp" $using:random_user /add | Out-Null
    }
    Write-Good "$random_user added to $($asset.hostname) to RDP group"
}
