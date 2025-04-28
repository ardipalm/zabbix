# Varukoopia baas tee ja maksimaalne koopiate arv
$BackupBasePath = "D:\backup"
$MaxCopies = 2
$LogFile = "zabbix.txt"

# Loo baas kaust, kui seda ei eksisteeri
if (!(Test-Path -Path $BackupBasePath)) {
    New-Item -ItemType Directory -Path $BackupBasePath | Out-Null
}

# Võta kõik VM-id
$VMList = Get-VM

foreach ($VM in $VMList) {
    $VMName = $VM.Name
    $BackupPath = Join-Path -Path $BackupBasePath -ChildPath $VMName

    # Loo VM-i jaoks eraldi kaust kui vaja
    if (!(Test-Path -Path $BackupPath)) {
        New-Item -ItemType Directory -Path $BackupPath | Out-Null
    }

    # Ekspordi VM
    $Timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $ExportPath = "$BackupPath\$VMName-$Timestamp"

    try {
        Export-VM -Name $VMName -Path $ExportPath -ErrorAction Stop

        # Logi backupi edukus, ainult kui eksport õnnestus
        $LogFilePath = "$BackupPath\$LogFile"
        $SuccessMessage = "$(Get-Date): Backup for VM '$VMName' completed successfully."
        Add-Content -Path $LogFilePath -Value $SuccessMessage
    }
    catch {
        # Kui eksport ebaõnnestub, ei tee midagi
    }

    # Halda koopiate arvu (säilita ainult $MaxCopies)
    $BackupFolders = Get-ChildItem -Path $BackupPath | Where-Object { $_.PSIsContainer } | Sort-Object LastWriteTime -Descending

    if ($BackupFolders.Count -gt $MaxCopies) {
        $FoldersToDelete = $BackupFolders | Select-Object -Skip $MaxCopies
        foreach ($Folder in $FoldersToDelete) {
            Remove-Item -Path $Folder.FullName -Recurse -Force
        }
    }
}
