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

Invoke-Command -ComputerName $config.domain.dcip -Credential $admin -ScriptBlock { 
    $domainAdmins = Get-AdGroupMember -Identity "Domain Admins" | Select name
    foreach($DA in $domainAdmins) {
        $user = Get-ADUser -Identity $DA.name | Select Enabled
        if (-not $user.Enabled) {
            $points += $config.domain.valueDomainAdmin
        }
    }

    $enterpriseAdmins = Get-AdGroupMember -Identity "Enterprise Admins" | Select name
    foreach($EA in $enterpriseAdmins) {
        $user = Get-ADUser -Identity $EA.name | Select Enabled
        if (-not $user.Enabled) {
            $points += $config.domain.valueEnterpriseAdmin
        }
    }

    # No worka bene
    $users = Get-AdUser -Filter * -Properties MemberOf
    foreach ($user in $users) { 
        $memberOf = $user.MemberOf # Verifica se l'utente non è membro dei gruppi Domain Admins e Domain Enterprise Admins
        if ($memberOf -notlike "*CN=Domain Admins*" -and $memberOf -notlike "*CN=Enterprise Admins*" -and -not $user.Enabled) {
            $points += $config.domain.valueSimpleUser
        } else {
            Write-Host $user
            Write-Host $user.Enabled
            Write-Host $memberOf
        }
    }
}
