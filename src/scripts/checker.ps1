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
$domain = $config.domain.name

$points = 0

$win_condition = $config.win_condition


for ($i=0; $i -lt $config.assets.Count; $i=$i+1 ) {
    $asset = $config.assets[$i]
    $hostname = "$($asset.hostname).$($domain)"
    $test = Test-Connection -ComputerName $hostname -Count 1 -ErrorAction SilentlyContinue
    if (-not $test.ProtocolAddress) {
        $points += $asset.value
    }
}
$asset = $config.domain
$hostname = "$($asset.hostname).$($domain)"
$test = Test-Connection -ComputerName $hostname -Count 1 -ErrorAction SilentlyContinue
if (-not $test.ProtocolAddress) {
    $points += $asset.value
}


# Create credential object for the local admin
$admin = New-Object System.Management.Automation.PSCredential -ArgumentList $($config.domain.admin), (ConvertTo-SecureString -String $config.domain.password -AsPlainText -Force)

$response = Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock { 
    $enterpriseAdmins = Get-AdGroupMember -Identity "Enterprise Admins" | Select name
    $win = $false
    foreach($EA in $enterpriseAdmins) {
        $user = Get-ADUser -Identity $EA.Name 
        if ($user.Enabled -eq $true -and $user.Name -eq $using:win_condition){
            $win = $true
        }
    }

    $domainAdmins = Get-AdGroupMember -Identity "Domain Admins" | Select name
    foreach($DA in $domainAdmins) {
        $user = Get-ADUser -Identity $DA.name | Select Enabled
        if (-not $user.Enabled) {
            $points += $using:config.domain.valueDomainAdmin
        }
    }

    $enterpriseAdmins = Get-AdGroupMember -Identity "Enterprise Admins" | Select name
    foreach($EA in $enterpriseAdmins) {
        $user = Get-ADUser -Identity $EA.name | Select Enabled
        if (-not $user.Enabled) {
            $points += $using:config.domain.valueEnterpriseAdmin
        }
    }

   
    $users = Get-AdUser -Filter * -Properties MemberOf
    $ListUsers=@()
    foreach ($user in $users) { 
        if ($user -like "*Guest*" -or $user -like "*krbtgt*") {
            continue
        }
        $memberOf = $user.MemberOf 
        $joinMemberOf = $memberOf -join ","
        if ($joinmemberOf -notlike "*CN=Domain Admins*" -and $joinmemberOf -notlike "*CN=Enterprise Admins*" -and -not $user.Enabled) {
           $points += $using:config.domain.valueSimpleUser
           $ListUsers += $user
        } 
    }
    # Write-Host $ListUsers
    Return @{
        points = $points
        win = $win
    }
}

$response | ConvertTo-Json