#!/bin/bash
apt-get update &>/dev/null
HOSTNAME_DEF=$(hostname)

# UFW_disable
tmpfile=$(mktemp -p /tmp)
dpkg --get-selections > $tmpfile
for pkg in exim4 postfix ufw; do
    if [ ! -z "$(grep $pkg $tmpfile)" ]; then
        conflicts="$pkg* $conflicts"
        apt-get -qq purge $conflicts -y
        check_result $? 'apt-get remove failed'
        unset $answer
    fi
done
rm -f $tmpfile

DOMAIN=$1
PASSWD=$2
SCRIPT=$3
PURSHCODE=$4

#if [ -z "$1" ]
#PASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\%\^\&\(\)-+= < /dev/urandom | head -c 12)
DBPASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 16)
DB=$(LC_CTYPE=C tr -dc a-z0-9 < /dev/urandom | head -c 5)
#DB=$(echo $DOMAIN | tr -dc "a-z" | cut -c 1-5)
IP=$(wget -O - -q ifconfig.me)
DIG_IP=$(getent ahostsv4 $DOMAIN | sed -n 's/ *STREAM.*//p')

#Prepare
hostnamectl set-hostname $DOMAIN
echo "$IP  $DOMAIN" >> /etc/hosts
#touch /etc/apt/sources.list.d/mariadb.list
#chattr +a /etc/apt/sources.list.d/mariadb.list

if grep -qs "ubuntu" /etc/os-release; then
	os="ubuntu"
	os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
	group_name="nogroup"
elif [[ -e /etc/debian_version ]]; then
	os="debian"
	os_version=$(grep -oE '[0-9]+' /etc/debian_version | head -1)
	group_name="nogroup"
fi

if [[ "$os" == "ubuntu" && "$os_version" -lt 1804 ]]; then
	echo "Ubuntu 18.04 "
fi

if [[ "$os" == "ubuntu" && "$os_version" -lt 2004 ]]; then
	echo "Ubuntu 20.04 "
fi

if [[ "$os" == "debian" && "$os_version" -lt 10 ]]; then
cat > /etc/apt/sources.list << HERE 
deb http://deb.debian.org/debian/ buster main
deb-src http://deb.debian.org/debian/ buster main
deb http://security.debian.org/debian-security buster/updates main
deb-src http://security.debian.org/debian-security buster/updates main
HERE
fi

mv /usr/sbin/reboot /usr/sbin/reboot_
wget https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install.sh
bash hst-install.sh --multiphp yes --clamav no --interactive no --hostname $DOMAIN --email admin@$DOMAIN --password $PASSWD 

#if [ "$DIG_IP" = "$IP" ]; then echo  "DNS lookup for $DOMAIN resolved to $DIG_IP, enabled ssl"
#/usr/local/vesta/bin/v-add-letsencrypt-domain admin $DOMAIN www.$DOMAIN "yes"
#fi

#DEB 
apt-get update 1>/dev/null
curl -sL https://deb.nodesource.com/setup_14.x | bash -
apt-get install -y nodejs htop redis-server php7.4-redis php8.0-redis 1>/dev/null
npm install forever -g
npm install forever-service -g
npm install pm2 -g
apt-get install ffmpeg -y --fix-missing 1>/dev/null
apt-get update 1>/dev/null
apt-get install ffmpeg -y 1>/dev/null
cp /home/admin/.composer/composer /usr/local/bin/

#Preset
eval "$(exec /usr/bin/env -i "${SHELL}" -l -c "export")"
grep -rl  "pm.max_children = 8" /etc/php /usr/local/hestia/data/templates/web/php-fpm | xargs perl -p -i -e 's/pm.max_children = 8/pm.max_children = 1000/g'
cp /usr/local/hestia/data/templates/web/php-fpm/PHP-7_4.tpl /usr/local/hestia/data/templates/web/php-fpm/new-PHP-7_4.tpl
cp /usr/local/hestia/data/templates/web/php-fpm/PHP-8_0.tpl /usr/local/hestia/data/templates/web/php-fpm/new-PHP-8_0.tpl
#sed -i "s/WEB_TEMPLATE='default'/WEB_TEMPLATE='default'\\nBACKEND_TEMPLATE='new-PHP-7_4'/g" /usr/local/hestia/data/packages/default.pkg
replace "BACKEND_TEMPLATE='default'" "BACKEND_TEMPLATE='new-PHP-7_4'" -- /usr/local/hestia/data/packages/default.pkg
cp /usr/local/hestia/data/packages/default.pkg /usr/local/hestia/data/packages/new.pkg
v-change-user-package admin new FORCE
v-rebuild-user admin
v-change-sys-hostname $DOMAIN
v-add-web-domain-alias admin $DOMAIN www.$DOMAIN
v-add-letsencrypt-domain admin $DOMAIN www.$DOMAIN
v-schedule-letsencrypt-domain admin $DOMAIN www.$DOMAIN
v-add-web-domain-ssl-force admin $DOMAIN
#v-add-web-domain-ssl-preset admin $DOMAIN
v-add-dns-domain admin $DOMAIN $IP
v-add-mail-domain admin $DOMAIN
#v-delete-mail-domain-antivirus admin $DOMAIN
v-delete-mail-domain-dkim admin $DOMAIN
v-add-mail-account admin $DOMAIN admin $PASSWD
v-add-mail-account admin $DOMAIN info $PASSWD
v-add-database admin $DB $DB $DBPASSWD
v-add-firewall-rule ACCEPT 0.0.0.0/0 449
v-change-web-domain-backend-tpl $user $DOMAIN new-PHP-7_4
v-add-letsencrypt-host

wget https://raw.githubusercontent.com/hestiacp/hestiacp/feature/v-restore-user-cpanel/bin/v-restore-user-cpanel -O /usr/local/hestia/bin/v-restore-user-cpanel
chmod +x /usr/local/hestia/bin/v-restore-user-cpanel
wget https://raw.githubusercontent.com/it-toppp/ultahost/main/hestiacp-templates/nginx/proxy3000.stpl -O /usr/local/hestia/data/templates/web/nginx/proxy3000.stpl
wget https://raw.githubusercontent.com/it-toppp/ultahost/main/hestiacp-templates/nginx/proxy3000.tpl -O /usr/local/hestia/data/templates/web/nginx/proxy3000.tpl
chmod 755 /usr/local/hestia/data/templates/web/nginx/proxy3000.tpl /usr/local/hestia/data/templates/web/nginx/proxy3000.stpl


#FIX FM
grep -rl "directoryPerm = 0744" /usr/local/hestia/web/fm/vendor/league/flysystem-sftp | xargs perl -p -i -e 's/directoryPerm = 0744/directoryPerm = 0755/g'
#mv /usr/local/hestia/web/fm/configuration.php /usr/local/hestia/web/fm/configuration.php_
#wget https://raw.githubusercontent.com/hestiacp/hestiacp/main/install/deb/filemanager/filegator/configuration.php -O /usr/local/hestia/web/fm/configuration.php
wget https://raw.githubusercontent.com/it-toppp/ultahost/main/fm/filemanager.sh -O /opt/filemanager.sh && chmod +x /opt/filemanager.sh && bash /opt/filemanager.sh
crontab -l | { cat; echo "11 11 * * * /bin/curl -SsL https://raw.githubusercontent.com/it-toppp/ultahost/main/fm/filemanager.sh | /bin/bash"; } | crontab -

wget http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar zxf ioncube_loaders_lin_x86-64.tar.gz 
rm -f xf ioncube_loaders_lin_x86-64.tar.gz
mv ioncube /usr/local 

#mysql
cat > /etc/mysql/conf.d/z_custom.cnf << HERE 
[mysqld]
    query_cache_size = 0
    query_cache_type = 0
    query_cache_limit = 8M
    join_buffer_size = 2M
    table_open_cache = 8192
    table_definition_cache = 1000
    thread_cache_size = 500
    tmp_table_size = 256M
    innodb_buffer_pool_size = 1G
    sql_mode = NO_ENGINE_SUBSTITUTION
    max_heap_table_size  = 256M
    max_allowed_packet = 1024M
    max_connections = 20000
    max_user_connections = 5000
    wait_timeout = 100000
       
HERE
systemctl restart  mysql 1>/dev/null
echo "Fix MYSQL successfully"

#Backup
hou=$(shuf -i 0-23 -n 1)
replace "MIN='10' HOUR='05' DAY='*'" "MIN='15' HOUR='$hou' DAY='*/2'" -- /usr/local/hestia/data/users/admin/cron.conf
sed -i "s|BACKUPS='1'|BACKUPS='3'|" /usr/local/hestia/data/packages/default.pkg
sed -i "s|BACKUPS='1'|BACKUPS='3'|" /usr/local/hestia/data/users/admin/user.conf

#PHP
multiphp_v=("7.0" "7.1" "7.2" "7.3" "7.4" "8.0")
for v in "${multiphp_v[@]}"; do
cat >>  /etc/php/$v/fpm/php.ini << HERE 
file_uploads = On
allow_url_fopen = On
post_max_size = 5120M
upload_max_filesize = 5120M
output_buffering = Off
max_execution_time = 6000
max_input_vars = 3000
max_input_time = 6000
zlib.output_compression = Off
memory_limit = 1000M
HERE

cat > /etc/php/$v/fpm/conf.d/00-ioncube.ini << HERE 
[Zend Modules]
zend_extension = /usr/local/ioncube/ioncube_loader_lin_$v.so
zend_extension_ts = /usr/local/ioncube/ioncube_loader_lin_$v_ts.so
HERE

cat >  /etc/php/$v/cli/conf.d/00-ioncube.ini << HERE
[Zend Modules]
zend_extension = /usr/local/ioncube/ioncube_loader_lin_$v.so
zend_extension_ts = /usr/local/ioncube/ioncube_loader_lin_$v_ts.so
HERE

systemctl restart php$v-fpm
done
echo "Fix PHP successfully"

#Apache
a2enmod headers
cat > /etc/apache2/mods-enabled/fcgid.conf << HERE 
<IfModule mod_fcgid.c>
  FcgidConnectTimeout 20
  ProxyTimeout 6000
  FcgidBusyTimeout 72000
  FcgidIOTimeout 72000
  IPCCommTimeout 72000
  MaxRequestLen 320000000000
  FcgidMaxRequestLen 320000000000
  <IfModule mod_mime.c>
    AddHandler fcgid-script .fcgi
  </IfModule>
</IfModule>
HERE

cat > /etc/apache2/mods-available/mpm_event.conf << HERE 
<IfModule mpm_event_module>
StartServers  2
MinSpareThreads  25
MaxSpareThreads 75
ThreadLimit 64
ThreadsPerChild 25
ServerLimit       2000
MaxRequestWorkers 2000
MaxConnectionsPerChild 0
</IfModule>
HERE
systemctl restart apache2  1>/dev/null

#nginx
sed -i 's|client_max_body_size            256m|client_max_body_size  5120m|' /etc/nginx/nginx.conf
sed -i 's|worker_connections  1024;|worker_connections  4096;|' /etc/nginx/nginx.conf
sed -i 's|send_timeout                    60;|send_timeout  3000;|' /etc/nginx/nginx.conf
sed -i 's|proxy_connect_timeout           30|proxy_connect_timeout   9000|' /etc/nginx/nginx.conf
sed -i 's|proxy_send_timeout              180|proxy_send_timeout  9000|' /etc/nginx/nginx.conf
sed -i 's|proxy_read_timeout              300|proxy_read_timeout  9000|' /etc/nginx/nginx.conf
systemctl restart nginx 1>/dev/null
echo "Fix NGINX successfully"

#SWAP
wget https://raw.githubusercontent.com/it-toppp/Swap/master/swap.sh -O swap && sh swap 2048
rm -Rf swap

mv /usr/sbin/reboot_ /usr/sbin/reboot
echo "Full installation completed [ OK ]"
#chown admin:www-data /home/admin/web/$DOMAIN/public_html

if [ ! -z "$SCRIPT" ]; then
curl -O https://raw.githubusercontent.com/it-toppp/ultahost/main/scripts/scriptsun.sh && bash scriptsun.sh $DOMAIN $SCRIPT $PURSHCODE
fi
echo '======================================='
echo -e "         
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
   http://$IP/phpmyadmin
   username=root
   $(grep pass /root/.my.cnf | tr --delete \')
   
DB:
   db_name: admin_$DB
   db_user: admin_$DB
   db_pass: $DBPASSWD
" | tee -a /root/.admin
cd /root && rm -Rf hestiacp.sh scriptsun.sh
history -c
