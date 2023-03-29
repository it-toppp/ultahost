#!/bin/bash
apt-get update &>/dev/null
HOSTNAME_DEF=$(hostname)

# UFW_disable
tmpfile=$(mktemp -p /tmp)
dpkg --get-selections > $tmpfile
for pkg in postfix ufw; do
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

wget https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install.sh
bash hst-install.sh --multiphp yes --clamav no --interactive no --hostname $DOMAIN --email admin@$DOMAIN --password $PASSWD 

#if [ "$DIG_IP" = "$IP" ]; then echo  "DNS lookup for $DOMAIN resolved to $DIG_IP, enabled ssl"
#/usr/local/vesta/bin/v-add-letsencrypt-domain admin $DOMAIN www.$DOMAIN "yes"
#fi

#Preset
eval "$(exec /usr/bin/env -i "${SHELL}" -l -c "export")"
grep -rl  "pm.max_children = 8" /etc/php /usr/local/hestia/data/templates/web/php-fpm | xargs perl -p -i -e 's/pm.max_children = 8/pm.max_children = 1000/g'
grep -rl  "php_admin_value\[open_basedir\]" /etc/php | xargs perl -p -i -e 's|php_admin_value\[open_basedir\]|;php_admin_value\[open_basedir\]|g'

cp /usr/local/hestia/data/templates/web/php-fpm/PHP-7_4.tpl /usr/local/hestia/data/templates/web/php-fpm/new-PHP-7_4.tpl
cp /usr/local/hestia/data/templates/web/php-fpm/PHP-8_1.tpl /usr/local/hestia/data/templates/web/php-fpm/new-PHP-8_1.tpl
cp /usr/local/hestia/data/templates/web/php-fpm/PHP-8_2.tpl /usr/local/hestia/data/templates/web/php-fpm/new-PHP-8_2.tpl
#sed -i "s/WEB_TEMPLATE='default'/WEB_TEMPLATE='default'\\nBACKEND_TEMPLATE='new-PHP-7_4'/g" /usr/local/hestia/data/packages/default.pkg
replace "BACKEND_TEMPLATE='default'" "BACKEND_TEMPLATE='new-PHP-7_4'" -- /usr/local/hestia/data/packages/default.pkg

hou=$(shuf -i 0-23 -n 1)
min=$(shuf -i 0-55 -n 1)
v-change-cron-job admin 7 45 $hou '*/3' '*' '*' 'sudo /usr/local/hestia/bin/v-backup-users'
sed -i "s|BACKUPS='1'|BACKUPS='3'|" /usr/local/hestia/data/packages/default.pkg
sed -i "s|BACKUPS='1'|BACKUPS='3'|" /usr/local/hestia/data/users/admin/user.conf
cp /usr/local/hestia/data/packages/default.pkg /usr/local/hestia/data/packages/new.pkg
v-change-user-package admin new FORCE
v-rebuild-user admin
v-change-sys-hostname $DOMAIN
v-add-letsencrypt-domain admin $DOMAIN
v-schedule-letsencrypt-domain admin $DOMAIN
v-add-web-domain-ssl-force admin $DOMAIN
v-add-dns-domain admin $DOMAIN $IP
v-add-mail-domain admin $DOMAIN
v-delete-mail-domain-dkim admin $DOMAIN
v-add-mail-account admin $DOMAIN admin $PASSWD
v-add-mail-account admin $DOMAIN info $PASSWD
v-add-firewall-rule ACCEPT 0.0.0.0/0 449
v-add-letsencrypt-host

#wget https://raw.githubusercontent.com/hestiacp/hestiacp/feature/v-restore-user-cpanel/bin/v-restore-user-cpanel -O /usr/local/hestia/bin/v-restore-user-cpanel
#chmod +x /usr/local/hestia/bin/v-restore-user-cpanel
wget https://raw.githubusercontent.com/it-toppp/ultahost/main/hestiacp-templates/nginx/proxy3000.stpl -O /usr/local/hestia/data/templates/web/nginx/proxy3000.stpl
wget https://raw.githubusercontent.com/it-toppp/ultahost/main/hestiacp-templates/nginx/proxy3000.tpl -O /usr/local/hestia/data/templates/web/nginx/proxy3000.tpl
chmod 755 /usr/local/hestia/data/templates/web/nginx/proxy3000.tpl /usr/local/hestia/data/templates/web/nginx/proxy3000.stpl

#FM
mkdir /etc/hestiacp/hooks
wget https://raw.githubusercontent.com/it-toppp/ultahost/main/hestia_post_install.sh -O /etc/hestiacp/hooks/post_install.sh
chmod +x /etc/hestiacp/hooks/post_install.sh
bash /etc/hestiacp/hooks/post_install.sh

#mysql
cat > /etc/mysql/conf.d/z_custom.cnf << HERE 
[mysqld]
innodb_buffer_pool_size = 300M
sql_mode = NO_ENGINE_SUBSTITUTION
max_allowed_packet = 1024M
max_connections = 10000
max_user_connections = 10000
wait_timeout = 10000
       
HERE
systemctl restart  mysql 1>/dev/null
echo "Fix MYSQL successfully"

#PHP
apt-get install -y redis-server php7.4-redis php8.1-redis php7.4-sqlite3 php8.1-sqlite3 php7.4-bcmath php8.1-bcmath php7.4-gmp php8.1-gmp php7.4-fileinfo php8.1-fileinfo
multiphp_v=("5.6" "7.0" "7.1" "7.2" "7.3" "7.4" "8.0" "8.1" "8.2")
for v in "${multiphp_v[@]}"; do
cat >>  /etc/php/$v/fpm/php.ini << HERE 
file_uploads = On
allow_url_fopen = On
allow_url_include = On
post_max_size = 10240M
upload_max_filesize = 10240M
output_buffering = Off
max_execution_time = 6000
max_input_vars = 10000
max_input_time = 6000
zlib.output_compression = Off
memory_limit = 512M
HERE
done

wget http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar zxf ioncube_loaders_lin_x86-64.tar.gz 
rm -f xf ioncube_loaders_lin_x86-64.tar.gz
mv ioncube /usr/local 
multiphp_v=("5.6" "7.0" "7.1" "7.2" "7.3" "7.4" "8.1")
for v in "${multiphp_v[@]}"; do
cat > /etc/php/$v/fpm/conf.d/00-ioncube.ini << HERE 
[Zend Modules]
zend_extension = /usr/local/ioncube/ioncube_loader_lin_$v.so
HERE
cat >  /etc/php/$v/cli/conf.d/00-ioncube.ini << HERE
[Zend Modules]
zend_extension = /usr/local/ioncube/ioncube_loader_lin_$v.so
HERE
systemctl restart php$v-fpm
done
echo "Fix PHP successfully"

#Apache
a2enmod headers 1>/dev/null
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
MaxClients          5000
</IfModule>
HERE
systemctl restart apache2  1>/dev/null

#NGINX
sed -i 's|client_max_body_size.\+|client_max_body_size  10240m;|' /etc/nginx/nginx.conf
sed -i 's|worker_connections.\+|worker_connections  4096;|' /etc/nginx/nginx.conf
sed -i 's|send_timeout.\+|send_timeout  9000;|' /etc/nginx/nginx.conf
sed -i 's|proxy_connect_timeout.\+|proxy_connect_timeout   9000;|' /etc/nginx/nginx.conf
sed -i 's|proxy_send_timeout.\+|proxy_send_timeout  9000;|' /etc/nginx/nginx.conf
sed -i 's|proxy_read_timeout.\+|proxy_read_timeout  9000;|' /etc/nginx/nginx.conf
sed -i 's|proxy_buffers.\+|proxy_buffers   4 512k;|' /etc/nginx/nginx.conf
sed -i '/proxy_buffers   4 512k;/ a \
    proxy_buffer_size   512k; \
    proxy_busy_buffers_size   512k; \
' /etc/nginx/nginx.conf
sed -i 's|open_file_cache_min_uses.\+|open_file_cache_min_uses 12;|' /etc/nginx/nginx.conf
systemctl restart nginx 1>/dev/null
echo "Fix NGINX successfully"

#DEB 
cp /home/admin/.composer/composer /usr/local/bin/
curl -sL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
npm install pm2 -g 1>/dev/null
npm install yarn -g 1>/dev/null
apt-get install ffmpeg -y

#SWAP
if [ ! -f "/swapfile" ]; then
wget https://raw.githubusercontent.com/it-toppp/Swap/master/swap.sh -O swap  1>/dev/null
sh swap 2048 1>/dev/null
rm -Rf swap  1>/dev/null
fi

echo "Full installation completed [ OK ]"

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
   username=root
   $(grep pass /root/.my.cnf | tr --delete \')
" | tee -a /root/.admin
cd /root && rm -Rf hestiacp.sh 
history -c
