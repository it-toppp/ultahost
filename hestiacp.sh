#!/bin/bash
apt-get update &>/dev/null
#apt install curl &>/dev/null

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
DBPASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 12)
DB=$(LC_CTYPE=C tr -dc a-z0-9 < /dev/urandom | head -c 5)
#DB=$(echo $DOMAIN | tr -dc "a-z" | cut -c 1-5)
IP=$(wget -O - -q ifconfig.me)
DIG_IP=$(getent ahostsv4 $DOMAIN | sed -n 's/ *STREAM.*//p')

#Prepare
hostnamectl set-hostname $DOMAIN
echo "$IP  $DOMAIN" >> /etc/hosts
touch /etc/apt/sources.list.d/mariadb.list
chattr +a /etc/apt/sources.list.d/mariadb.list

wget https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install.sh
bash hst-install.sh --multiphp yes --clamav no --interactive no --hostname $DOMAIN --email admin@$DOMAIN --password $PASSWD 

#if [ "$DIG_IP" = "$IP" ]; then echo  "DNS lookup for $DOMAIN resolved to $DIG_IP, enabled ssl"
#/usr/local/vesta/bin/v-add-letsencrypt-domain admin $DOMAIN www.$DOMAIN "yes"
#fi

#DEB 
apt-get update 1>/dev/null
curl -sL https://deb.nodesource.com/setup_14.x | bash -
apt-get install -y nodejs htop redis-server php7.4-redis php7.2-redis 1>/dev/null
npm install forever -g
apt-get install ffmpeg -y --fix-missing 1>/dev/null
apt-get update 1>/dev/null
apt-get install ffmpeg -y 1>/dev/null
cp /home/admin/.composer/composer /usr/local/bin/

#Preset
eval "$(exec /usr/bin/env -i "${SHELL}" -l -c "export")"
v-change-sys-hostname $DOMAIN
v-add-web-domain-alias admin $DOMAIN www.$DOMAIN
v-add-letsencrypt-domain admin $DOMAIN www.$DOMAIN
v-schedule-letsencrypt-domain admin $DOMAIN www.$DOMAIN
v-add-web-domain-ssl-force admin $DOMAIN
#v-add-web-domain-ssl-preset admin $DOMAIN
v-add-letsencrypt-host
v-add-dns-domain admin $DOMAIN $IP
v-add-mail-domain admin $DOMAIN
v-delete-mail-domain-antivirus admin $DOMAIN
v-delete-mail-domain-dkim admin $DOMAIN
v-add-mail-account admin $DOMAIN admin $PASSWD
v-add-mail-account admin $DOMAIN info $PASSWD
v-add-database admin $DB $DB $DBPASSWD
v-add-firewall-rule ACCEPT 0.0.0.0/0 3000,449
sed -i "s|BACKUPS='1'|BACKUPS='3'|" /usr/local/hestia/data/packages/default.pkg
sed -i "s|BACKUPS='1'|BACKUPS='3'|" /usr/local/hestia/data/users/admin/user.conf

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
#sed -i 's|max_connections=200|max_connections=2000|' /etc/mysql/my.cnf
#sed -i 's|max_user_connections=50|max_user_connections=500|' /etc/mysql/my.cnf
#sed -i 's|wait_timeout=10|wait_timeout=10000|' /etc/mysql/my.cnf
#sed -i 's|#innodb_use_native_aio = 0|sql_mode=NO_ENGINE_SUBSTITUTION|' /etc/mysql/my.cnf
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

#PHP
grep -rl  "pm.max_children = 8" /etc/php /usr/local/hestia/data/templates/web | xargs perl -p -i -e 's/pm.max_children = 8/pm.max_children = 100/g'

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

echo "Full installation completed [ OK ]"
#chown admin:www-data /home/admin/web/$DOMAIN/public_html

if [ ! -z "$SCRIPT" ]; then
curl -O https://raw.githubusercontent.com/it-toppp/ultahost/main/scripts/scriptsun.sh && bash scriptsun.sh $DOMAIN $SCRIPT $PURSHCODE
fi
echo '======================================================='
echo -e "         
Vesta Control Panel:
    https://$DOMAIN:8083  or  https://$IP:8083
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
   
phpMyAdmin:
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
