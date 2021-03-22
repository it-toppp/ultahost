#!/bin/bash
DOMAIN=$1
SCRIPT=$2
PURSHCODE=$3
user=admin
WORKINGDIR="/home/$user/web/$DOMAIN/public_html"
#PASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\%\^\&\(\)-+= < /dev/urandom | head -c 12)
DBPASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 12)
DB=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 5)
IP=$(wget -O - -q ifconfig.me)

echo "$IP  $DOMAIN" >> /etc/hosts
v-add-database admin $DB $DB $DBPASSWD
cd $WORKINGDIR
rm -fr $WORKINGDIR/{*,.*} &> /dev/null

if [ ! -d "/home/admin/web/$DOMAIN/public_html" ]; then
v-add-web-domain admin $DOMAIN $IP yes www.$DOMAIN
v-add-letsencrypt-domain admin $DOMAIN www.$DOMAIN
fi
if [ ! -f "/home/$user/conf/web/ssl.$DOMAIN.pem" ]; then
    v-add-letsencrypt-domain "$user" "$DOMAIN" "www.$DOMAIN"
fi
if [ "$SCRIPT" = "wowonder-null" ] || [ "$SCRIPT" = "wowonder" ]; then
v-change-web-domain-backend-tpl admin $DOMAIN PHP-7_2
fi

function wordpress() {
rm -rf /home/$user/wp
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /home/$user/wp
cd /home/$user/web/$DOMAIN/public_html
sudo -H -u$user /home/$user/wp core download
sudo -H -u$user /home/$user/wp core config --dbname=$user_$DB --dbuser=$user_$DB --dbpass=$DBPASSWD
sudo -H -u$user /home/$user/wp core install --url="$DOMAIN" --title="$DOMAIN" --admin_user="admin" --admin_password="$password" --admin_email="$email" --path=$WORKINGDIR
#FIX za https://github.com/wp-cli/wp-cli/issues/2632
mysql -u$admin_$DB -p$DBPASSWD -e "USE admin_$DB; update wp_options set option_value = 'https://$DOMAIN' where option_name = 'siteurl'; update wp_options set option_value = 'https://$DOMAIN' where option_name = 'home';"
chown -R $user:$user $WORKINGDIR
rm -rf /home/$user/wp
}

function scriptsun() {
wget http://ss.ultahost.com/$SCRIPT.zip
unzip -qo $SCRIPT.zip
chmod 777 ffmpeg/ffmpeg upload cache ffmpeg/ffmpeg sys/ffmpeg/ffmpeg ./assets/import/ffmpeg/ffmpeg  &> /dev/null
curl -L --fail --silent --show-error --post301 --insecur \
     --data-urlencode "purshase_code=$PURSHCODE" \
     --data-urlencode "sql_host=localhost" \
     --data-urlencode "sql_user=admin_$DB" \
     --data-urlencode "sql_pass=$DBPASSWD" \
     --data-urlencode "sql_name=admin_$DB" \
     --data-urlencode "site_url=https://$DOMAIN" \
     --data-urlencode "siteName=$DOMAIN" --data-urlencode "site_name=$DOMAIN" \
     --data-urlencode "siteTitle=$DOMAIN" --data-urlencode "site_title=$DOMAIN" \
     --data-urlencode "siteEmail=info@$DOMAIN" --data-urlencode "site_email=admin@$DOMAIN" \
     --data-urlencode "admin_username=admin" \
     --data-urlencode "admin_password=$DBPASSWD" \
     --data-urlencode "install=install" \
http://$DOMAIN/install/?page=installation | grep -o -e "Failed to connect to MySQL" -e "successfully installed" -e "Wrong purchase code" -e "This code is already used on another domain"  
}

if [ "$SCRIPT" = "pixelphoto" ]; then
  mv ./install/index.php ./install.php_old
  wget https://raw.githubusercontent.com/it-toppp/ultahost/main/scripts/pixelphoto/installer.php -O ./install/index.php
fi

#wowonder,playtube,deepsound
if [ "$SCRIPT" = "wowonder-null" ] || [ "$SCRIPT" = "playtube" ] || [ "$SCRIPT" = "deepsound" ]; then
     scriptsun
     mysql admin_$DB -e "UPDATE config SET value = 'on' WHERE  name = 'ffmpeg_system';" &> /dev/null
     mysql admin_$DB -e "UPDATE config SET value = '/usr/bin/ffmpeg' WHERE  name = 'ffmpeg_binary_file';" &> /dev/null
fi
#pixelphoto
if [ "$SCRIPT" = "pixelphoto" ]; then
     scriptsun
     mysql admin_$DB -e "UPDATE pxp_config SET value = 'on' WHERE  name = 'ffmpeg_sys';" &> /dev/null
     mysql admin_$DB -e "UPDATE pxp_config SET value = '/usr/bin/ffmpeg' WHERE  name = 'ffmpeg_binary_file';" &> /dev/null
fi
#quickdate
if [ "$SCRIPT" = "quickdate" ]; then
     scriptsun
     mysql admin_$DB -e "UPDATE options SET option_value = '1' WHERE  option_name = 'ffmpeg_sys';" &> /dev/null
     mysql admin_$DB -e "UPDATE options SET option_value = '/usr/bin/ffmpeg' WHERE option_name = 'ffmpeg_binary';" &> /dev/null
fi
# wordpress
if [ "$SCRIPT" = "wordpress" ]; then
   wordpress
fi
chown -R $user:$user $WORKINGDIR
cat > htaccess_tmp << HERE
# Redirects http to https protocol
RewriteCond %{HTTPS} !on
RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
# Redirects www to non-www
RewriteCond %{HTTP_HOST} ^www\.(.*)$ [NC]
RewriteRule ^(.*)$ https://%1/\$1 [R=301,L]
HERE
sed -i -e '/RewriteEngine/r htaccess_tmp' .htaccess

if grep -wqorP $DOMAIN /home/admin/web/$DOMAIN/public_html; then
    rm -r ./install  __MACOSX $SCRIPT.zip  &> /dev/null

    echo -e "Installation $SCRIPT is successfully:
    https://$DOMAIN
    username: admin
    password: $DBPASSWD
" | tee -a /root/.admin
else
  echo Script $SCRIPT dont installed
fi
