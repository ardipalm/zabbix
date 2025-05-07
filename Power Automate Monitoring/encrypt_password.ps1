$Secure = Read-Host -AsSecureString
$Encrypted = ConvertFrom-SecureString -SecureString $Secure -Key (1..16)
$Encrypted | Set-Content "C:\Skriptid\Zabbix\Flow monitoring\dnkjshrfoqueiytuywoie.txt"
#$Secure2 = Get-Content "C:\Skriptid\Zabbix\Flow monitoring\temp.txt" | ConvertTo-SecureString -Key (1..16)


