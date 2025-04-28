Kopeeri Hyper-V serverisse skript vms-backup.ps1

Muuda seal muutujad
$BackupBasePath = "D:\backup"
$MaxCopies = 2
$LogFile = "zabbix.txt"

Task Scheduleri impordi vm-export.xml ja vaata üle selle seadistused.
Käivita see task.

Hyper-V serveris muuda C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf
Lisa selle lõppu rida (D:\backup asemele pane sama, mis oli skriptis $BackupBasePath )
UserParameter=backup.subfolders.discovery,powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $folders = Get-ChildItem -Path 'D:\backup' -Directory | Select-Object -ExpandProperty Name; $data = @(); foreach ($folder in $folders) { $data += @{ '{#FOLDERNAME}' = $folder } }; $json = @{ data = $data } | ConvertTo-Json -Compress; Write-Output $json }"

Zabbixi serverisse impordi Template zbx_export_templates.yaml
Hyper-V hostile lisa template Backup Folder Monitoring
Vaata üle ja vajadusel muuda  MACROd 
{$BACKUP.OLDER.THAN}
{$BACKUP_LOG}
{$BACKUP_PATH}