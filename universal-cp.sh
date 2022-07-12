
#!/usr/bin/env bash

domain=$1
password=$2
IP=$(wget -O - -q ifconfig.me)

function hestiacp() {
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/usr/local/hestia/bin"
/usr/local/hestia/bin/v-change-database-host-password mysql localhost root $password
/usr/local/hestia/bin/v-change-user-password admin $password
/usr/bin/mysqladmin -u root password $password
/usr/bin/sed -i "1s/password .\+/ password=$password/g"   /root/.my.cnf
/usr/local/hestia/bin/v-update-sys-ip
/usr/bin/sed -i "4s/RemoteIPInternalProxy .\+/RemoteIPInternalProxy $IP/g" /etc/apache2/mods-available/remoteip.conf
/usr/local/hestia/bin/v-change-sys-hostname $domain
/usr/local/hestia/bin/v-add-letsencrypt-host
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
    username: admin
    password: $password
SSH:
   host: $IP
   username: root
   password: $password
" | tee -a /root/.admin
}

function cyberpanel() {
mysql cyberpanel -e "ALTER USER 'cyberpanel'@'localhost' IDENTIFIED BY '$password';"
/usr/bin/mysqladmin --defaults-file=/root/.my.cnf -u root password $password
/usr/bin/sed -i "s/\'PASSWORD.\+/PASSWORD\'\: \'$password\',/g" /usr/local/CyberCP/CyberCP/settings.py
/usr/bin/sed -i "s/password.\+/password=$password/g" /root/.my.cnf
echo $IP > /etc/cyberpanel/machineIP
echo $password > /etc/cyberpanel/adminPass
echo $password > /etc/cyberpanel/mysqlPassword
/usr/bin/adminPass $password
/usr/bin/cyberpanel createWebsite --package Default --owner admin --domainName $domain --email user@ultasrv.com --php 8.0
/usr/bin/cyberpanel hostNameSSL --domainName $domain
systemctl restart lscpd
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
cyberpanel
fi

if [ -d "/etc/cyberpanel" ]; then
cyberpanel
fi

if [ -d "/www/server/panel/BTPanel" ]; then
aapanel
fi
