#Install-Module -Name Microsoft.PowerApps.Administration.PowerShell
# Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Force -AllowClobber
param (
    [string]$UserIdIn,
    [string]$SecretFilePathIn,
    [string]$ExcludeRegex
)

#$SecretFilePath="C:\skriptid\Zabbix\Flow monitoring\jk3djklsjdajakla.txt"

$SecretFilePath = $SecretFilePathIn -replace '/', '\'
$UserId = $UserIdIn -replace '%40', '@'

#Write-Host $SecretFilePathIn
#Write-Host $SecretFilePath
#Write-Host $UserId

Import-Module Microsoft.PowerApps.Administration.PowerShell 3>$null
Import-Module Microsoft.PowerApps.PowerShell 3>$null

# Read the password from the file and convert it to a secure string
$pass = Get-Content $SecretFilePath | ConvertTo-SecureString -Key (1..16)

# Use Add-PowerAppsAccount for authentication
Add-PowerAppsAccount -Username $UserId -Password $pass

# Retrieve list of environments
$environments = Get-AdminPowerAppEnvironment

$flowsList = @()

# If there's an exclude regex, compile it
$ExcludeRegex = if ($ExcludeRegex) { 
    try {
        [regex]::new($ExcludeRegex)
    } catch {
        Write-Warning "Invalid regular expression: $ExcludeRegex"
        $null
    }
}

foreach ($env in $environments) {
    $envId = $env.EnvironmentName
    $envDisplay = $env.DisplayName

    # Retrieve flows for each environment
    $flows = Get-AdminFlow -EnvironmentName $envId
    foreach ($flow in $flows) {
        $flowName = $flow.DisplayName
        $flowId = $flow.FlowName
        $flowWorkflowEntityId = $flow.WorkflowEntityId

        if ($ExcludeRegex -and $flowName -match $ExcludeRegex) {
            continue
        } 
        else
        {

        $flowsList += @{
            "{#FLOWID}"   = $flowId
            "{#FLOWNAME}" = $flowName
            "{#ENVID}"    = $envId
            "{#ENVNAME}"  = $envDisplay
            "{#ENTID}"    = if($flowWorkflowEntityId -ne $null) { $flowWorkflowEntityId } else { "none" }
        }}
    }
}

# Output for Zabbix discovery
$result = @{ data = $flowsList }
$result | ConvertTo-Json -Depth 3
