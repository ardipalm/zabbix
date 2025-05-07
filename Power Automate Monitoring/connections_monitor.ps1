param (
    [string]$UserId,            # The user to filter connections for
    [string]$SecretFilePath,     # Path to the file containing the password
    [string]$EnvId,               # The environment ID to check
    [string]$FlowId
)

# Suppress module import warnings
Import-Module Microsoft.PowerApps.Administration.PowerShell 3>$null
Import-Module Microsoft.PowerApps.PowerShell 3>$null

# Read password and log in
$pass = Get-Content $SecretFilePath | ConvertTo-SecureString -Key (1..16)
Add-PowerAppsAccount -Username $UserId -Password $pass | Out-Null

# Get flow object
$flow = Get-Flow -EnvironmentName $EnvId -FlowName $FlowId
#$flow.Internal.properties.connectionReferences | ConvertTo-Json -Depth 10

if (-not $flow) {
    Write-Error "Flow not found"
    exit 1
}

$flowName = $flow.DisplayName
$usedConnNames = @()

# Extract connection names from flow
foreach ($conn in $flow.Internal.properties.connectionReferences.PSObject.Properties) {
    $connPath = $conn.Value.connectionName
    if ($connPath) {
        $connId = ($connPath -split "/")[-1]
        $usedConnNames += $connId
    }
}

# Get all environment connections
$allConnections = Get-AdminPowerAppConnection -EnvironmentName $EnvId

# Filter those used by this flow
$matchedConnections = $allConnections | Where-Object {
    $usedConnNames -contains $_.ConnectionName
} | Sort-Object -Property ConnectionName -Unique

# Build discovery output
$discovery = @()
$allConnected = $true  # Assume all are connected initially

foreach ($conn in $matchedConnections) {
    # Check connection status
    $status = $conn.Statuses[0].status
    if ($status -ne "Connected") {
        $allConnected = $false
    }

    # Add connection to discovery output
    $discovery += @{
        "{#CONNID}"      = $conn.ConnectionName
        "{#DISPLAYNAME}" = $conn.DisplayName
        "{#STATUS}"      = $conn.Statuses[0].status
        "{#FLOWNAME}"    = $flowName
        "{#ENVID}"       = $EnvId
    }
}

# Output for Zabbix
#@{ data = $discovery } | ConvertTo-Json -Depth 3

# Return 1 if all connections are connected, else return 0
if ($allConnected) {
    Write-Output 1
} else {
    Write-Output 0
}