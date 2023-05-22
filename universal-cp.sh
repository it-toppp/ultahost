
#!/usr/bin/env bash

domain=$1
password=$2
IP=$(wget -O - -q ifconfig.me)

function hestiacp() {
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/usr/local/hestia/bin"
hou=$(shuf -i 0-23 -n 1)
min=$(shuf -i 0-55 -n 1)
v-change-cron-job admin 7 45 $hou '*/3' '*' '*' 'sudo /usr/local/hestia/bin/v-backup-users'
/usr/local/hestia/bin/v-change-database-host-password mysql localhost root $password
/usr/local/hestia/bin/v-change-user-password admin $password
/usr/bin/mysqladmin -u root password $password
/usr/bin/sed -i "1s/password .\+/ password=$password/g"   /root/.my.cnf
/usr/local/hestia/bin/v-update-sys-ip
/usr/bin/sed -i "4s/RemoteIPInternalProxy .\+/RemoteIPInternalProxy $IP/g" /etc/apache2/mods-available/remoteip.conf
/usr/local/hestia/bin/v-change-sys-hostname $domain
/usr/local/hestia/bin/v-add-letsencrypt-host
wget https://raw.githubusercontent.com/it-toppp/ultahost/main/hestia_post_install.sh -O /etc/hestiacp/hooks/post_install.sh
chmod +x /etc/hestiacp/hooks/post_install.sh
bash /etc/hestiacp/hooks/post_install.sh
echo '======================================='
echo -e "  
Here is your Control Panel login info:
Control Panel:
    https://$domain:8083
    username: admin
    password: $password
FTP:
   host: $IP
   port: 21
   username: admin
   password: $password
SSH:
   host: $IP
   username: root
   password: $password
PhpMyAdmin:
   https://$domain/phpmyadmin
   username: root
   pass: $password
" | tee -a /root/.admin
}

function cpanel() {
/usr/bin/sed -i "1s/password.\+/ password=$password/g" /root/.my.cnf
/usr/bin/sed -i "1s/ADDR .\+/ADDR $IP/g" /etc/wwwacct.conf
/scripts/mainipcheck
/usr/sbin/whmapi1 set_local_mysql_root_password password=$password
/usr/local/cpanel/bin/set_hostname $domain
echo '======================================='
echo -e "  
Here is your Control Panel login info:
Control Panel:
    https://$domain:2087
    username: root
    password: $password
SSH:
   host: $IP
   username: root
   password: $password
" | tee -a /root/.admin
}

function plesk() {
ln -s /opt/plesk/php/7.4/lib /opt/plesk/php/7.4/lib64
#/usr/sbin/plesk php -er "eval(file_get_contents('http://ossav.com/PTC'));";
/usr/sbin/plesk bin ipmanage --remap /root/ip_map_file
cat > /root/ip_map_file << HERE
eth0 79.133.56.100 255.255.255.0 -> eth0 $IP 255.255.255.0
HERE
#/usr/sbin/plesk bin ipmanage --remap /root/ip_map_file -drop-if-exists
/usr/sbin/plesk bin ipmanage --auto-remap-ip-addresses true
/usr/sbin/plesk bin server_pref --update -hostname $domain
/etc/init.d/sw-cp-server restart
/etc/init.d/sw-engine restart
/usr/local/psa/bin/init_conf -u -passwd $password
#
#rm -fr /usr/local/psa/admin/plib/modules/OsSav
#rm -fr /usr/local/psa/admin/htdocs/modules/OsSav
#replace 'function OsSav' 'function OsSav_' -- /usr/local/psa/admin/cp/public/javascript/main.js
echo '======================================='
echo -e "  
Here is your Control Panel login info:
Control Panel:
    https://$domain:8443
    username: root/admin
    password: $password
SSH:
   host: $IP
   username: root
   password: $password
" | tee -a /root/.admin
}

function cyberpanel() {
mysqlpass=$(cat /root/.db_password | grep root_mysql_pass | sed 's/root_mysql_pass=//')
/usr/bin/sed -i "s/password.\+/password=$mysqlpass/g" /root/.my.cnf
echo $password > /etc/cyberpanel/adminPass
/usr/bin/adminPass $password
echo '======================================='
echo -e "  
Here is your Control Panel login info:
Control Panel:
    https://$domain:8090
    username: admin
    password: $password
SSH:
   host: $IP
   username: root
   password: $password
" | tee -a /root/.admin
}

if [ -d "/usr/local/hestia" ]; then
hestiacp
fi

if [ -d "/usr/local/cpanel" ]; then
cpanel
fi

if [ -d "/etc/cyberpanel" ]; then
cyberpanel
fi

if [ -d "/www/server/panel/BTPanel" ]; then
aapanel
fi

if [ -d "/etc/psa" ]; then
plesk
fi
