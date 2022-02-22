#!/bin/bash

DOMAIN=$1
PASSWD=$2
#v-change-user-contact admin $EMAIL

ADMINPASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 16)
DBPASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 16)
apt-get update -y 1>/dev/null
v-change-database-host-password mysql localhost root $DBPASSWD
v-change-user-password admin $PASSWD
v-update-sys-ip
v-change-sys-hostname $DOMAIN
v-add-letsencrypt-host


SWAP
wget https://raw.githubusercontent.com/it-toppp/Swap/master/swap.sh -O swap 1>/dev/null
sh swap 2048 1>/dev/null

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
   pass: $DBPASSWD

" | tee -a /root/.admin
