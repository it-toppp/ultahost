#!/usr/bin/env bash

domain=$1
password=$2
IP=$(wget -O - -q ifconfig.me)
#
#/usr/bin/mysqladmin --defaults-file=/root/.my.cnf -u root password $password
#/usr/bin/sed -i "s/password.\+/password=$password/g" /root/.my.cnf
#mysql -uroot -p$password cyberpanel -e "ALTER USER 'cyberpanel'@'localhost' IDENTIFIED BY '$password';"
#/usr/bin/sed -i "s/'PASSWORD.\+/'PASSWORD'\: '$password',/g" /usr/local/CyberCP/CyberCP/settings.py
#/usr/bin/sed -i "s/MYSQLPassword .\+/MYSQLPassword $password/g" /etc/pure-ftpd/pureftpd-mysql.conf
#/usr/bin/sed -i "s/MYSQLPassword .\+/MYSQLPassword $password/g" /etc/pure-ftpd/db/mysql.conf
#/usr/bin/sed -i "s/password =.\+/password = $password/g" /etc/postfix/mysql-virtual_*
#/usr/bin/sed -i "s/gmysql-password=.\+/gmysql-password=$password/g" /etc/powerdns/pdns.conf
#/usr/bin/sed -i "s/gmysql-password=.\+/gmysql-password=$password/g" /etc/pdns/pdns.conf
#/usr/bin/sed -i "s/password=.\+/password=$password/g" /etc/dovecot/dovecot-sql.conf.ext
#echo $password > /etc/cyberpanel/mysqlPassword
#echo $IP > /etc/cyberpanel/machineIP
echo $password > /etc/cyberpanel/adminPass
/usr/bin/adminPass $password
#/usr/bin/cyberpanel createWebsite --package Default --owner admin --domainName $domain --email user@ultasrv.com --php 8.0
#/usr/bin/cyberpanel hostNameSSL --domainName $domain
systemctl restart lscpd
#systemctl restart pure-ftpd*
#systemctl restart pdns
#systemctl restart postfix
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
