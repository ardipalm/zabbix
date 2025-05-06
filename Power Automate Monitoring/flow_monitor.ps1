param (
    [string]$UserId,
    [string]$SecretFilePath,
    [string]$EnvId,
    [string]$FlowId,
    [ValidateSet("status", "runcheck")]
    [string]$Mode
)

# Import required modules, suppressing warnings
Import-Module Microsoft.PowerApps.Administration.PowerShell 3>$null
Import-Module Microsoft.PowerApps.PowerShell 3>$null

# Read password and log in
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

        # Check flow runs in the last 2 hours
        $Start = (Get-Date).AddHours(-2)
        $End = Get-Date

        $runs = Get-FlowRun -EnvironmentName $EnvId -FlowName $FlowId |
                Where-Object {  
                    $date = Get-Date $_.StartTime
                    $date -ge $Start -and $date -lt $End
                }

        $hasFailure = $runs | Where-Object { $_.Status -eq 'Failed' }
        Write-Output $([int]($hasFailure -ne $null))
    }

    "status" {
        $flow = Get-AdminFlow -EnvironmentName $EnvId -FlowName $FlowId
        Write-Output $([int]($flow.Enabled))
    }
}
