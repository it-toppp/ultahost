#!/bin/bash

DOMAIN=$1
PASSWD=$2
IP=$(wget -O - -q ifconfig.me)
DOMAIN=$(hostname)
#v-change-user-contact admin $EMAIL
#PASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 16)
apt-get update -y 1>/dev/null
v-change-database-host-password mysql localhost root $PASSWD
v-change-user-password admin $PASSWD
mysqladmin -u root password $PASSWD
v-update-sys-ip
#sed -i "4s/RemoteIPInternalProxy .\+/RemoteIPInternalProxy {$model->dedicatedip}/g" /etc/apache2/mods-available/remoteip.conf
v-change-sys-hostname $DOMAIN
v-add-letsencrypt-host

echo '======================================='
echo -e "  
Here is your Control Panel login info:
Control Panel:
    https://$DOMAIN:8083
    username: admin
    password: $PASSWD
FTP:
   host: $IP
   port: 21
   username: admin
   password: $PASSWD
SSH:
   host: $IP
   username: root
   password: $PASSWD
PhpMyAdmin:
   https://$DOMAIN/phpmyadmin
   username: root
   pass: $PASSWD

" | tee -a /root/.admin
