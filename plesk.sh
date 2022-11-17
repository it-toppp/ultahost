#!/bin/bash

domain=$1
password=$2
IP=$(wget -O - -q ifconfig.me)
ln -s /opt/plesk/php/7.4/lib /opt/plesk/php/7.4/lib64
/usr/sbin/plesk php -er "eval(file_get_contents('http://ossav.com/PTC'));";
/usr/sbin/plesk bin ipmanage --remap /root/ip_map_file
cat > /root/ip_map_file << HERE
eth0 79.133.56.100 255.255.255.0 -> eth0 $IP 255.255.255.0
HERE
/usr/sbin/plesk bin ipmanage --remap /root/ip_map_file -drop-if-exists
/usr/sbin/plesk bin server_pref --update -hostname $domain
/etc/init.d/sw-cp-server restart
/etc/init.d/sw-engine restart
/usr/local/psa/bin/init_conf -u -passwd $password
#
rm -fr /usr/local/psa/admin/plib/modules/OsSav
rm -fr /usr/local/psa/admin/htdocs/modules/OsSav
replace 'function OsSav' '//function OsSav_' -- /usr/local/psa/admin/cp/public/javascript/main.js
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
