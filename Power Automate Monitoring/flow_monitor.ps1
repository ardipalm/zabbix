# flow_monitor.ps1 "$1" "$2" "$3" "$4" "runcheck"
# flow_monitor.ps1 "siseveeb%40harku.ee" "C:/Skriptid/Zabbix/Flow monitoring/wdhjklsjdsldjsdjsl.txt" "Default-a0110b71-d476-43c1-921b-c0826e2bc143" "82e7d940-9a08-f011-bae2-7c1e5234c2a0" "runcheck"
param (
    [string]$UserIdIn,
    [string]$SecretFilePathIn,
    [string]$EnvId,
    [string]$FlowId,
    [ValidateSet("status", "runcheck")]
    [string]$Mode
)

#$UserIdIn = "siseveeb%40harku.ee"
#$SecretFilePathIn = "C:/Skriptid/Zabbix/Flow monitoring/wdhjklsjdsldjsdjsl.txt"
#$EnvId = "Default-a0110b71-d476-43c1-921b-c0826e2bc143"
#$FlowId =  "82e7d940-9a08-f011-bae2-7c1e5234c2a0"
#$Mode = "runcheck"

# Normaliseeri sisendid
$SecretFilePath = $SecretFilePathIn -replace '/', '\'
$UserId = $UserIdIn -replace '%40', '@'

# Import required modules, suppressing warnings
Import-Module Microsoft.PowerApps.Administration.PowerShell 3>$null
Import-Module Microsoft.PowerApps.PowerShell 3>$null


# Sisselogimine
# NB! Eeldab, et failis on eelnevalt AES-keyga krüpteeritud secure string (ConvertFrom/To-SecureString -Key)
$pass = Get-Content $SecretFilePath | ConvertTo-SecureString -Key (1..16)
Add-PowerAppsAccount -Username $UserId -Password $pass

switch ($Mode) {
    "runcheck" {
        # Get flow (sanity check)
        $flow = Get-Flow -EnvironmentName $EnvId -FlowName $FlowId
        if (-not $flow) {
            Write-Error "Flow not found"
            exit 2
        }

        # Check flow runs in the last 24 hours
        $Start = (Get-Date).AddHours(-24)
        $End = Get-Date

        $runs = Get-FlowRun -EnvironmentName $EnvId -FlowName $FlowId |
                Where-Object {  
                    $date = Get-Date $_.StartTime
                    $date -ge $Start -and $date -lt $End
                }

        $hasFailure = $runs | Where-Object { $_.Status -eq 'Failed' }
        Write-Output $([int][bool]($hasFailure))
    }

    "status" {
        $flow = Get-AdminFlow -EnvironmentName $EnvId -FlowName $FlowId
        Write-Output $([int]($flow.Enabled))
    }
}
