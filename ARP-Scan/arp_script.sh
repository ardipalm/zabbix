# Kopeeri asukohta /usr/local/bin/
# Muuda ära muutujad
# apt install arp-scan
# apt install zabbix-sender
# Lisa discovery ja itemi Allowed hosts
# apt install cron
# crontab -e
# */10 * * * * /usr/local/bin/arp_script.sh


interfaces="eth0"
zabbix_conf="/etc/zabbix/zabbix_agent2.conf"
arp_scan="sudo /usr/sbin/arp-scan"
sender="/usr/bin/zabbix_sender"

fullData=`for iface in $interfaces
do
        $arp_scan --localnet --interface=$iface -q -x | sort | uniq
done`
IFS=$'\n'
first=1
lld="{ \"data\":["
for entry in $fullData
do
        if [[ first -eq 0 ]]
        then
                lld="${lld},"
        else
                first=0
        fi
        ipAddress=`echo $entry | awk '{print $1}'`
        HWAddress=`echo $entry | awk '{print $2}'`
        lld="${lld}{"
        lld="${lld}\"ipAddress\":\"${ipAddress}\","
        lld="${lld}\"HWAddress\":\"${HWAddress}\""
        lld="${lld}}"
done
lld="${lld}]}"
$sender -c $zabbix_conf -k arp.discovery -o $lld
for mac in `echo "$fullData" | awk '{print $2}'| sort | uniq`
do
        ips=`echo "$fullData" | grep "$mac" | awk '{print $1}' | tr '\n' ' '`
        $sender -c $zabbix_conf -k arp.macIps[$mac] -o $ips
done
