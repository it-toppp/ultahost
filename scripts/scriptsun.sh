#!/bin/bash
DOMAIN=$1
SCRIPT=$2
PURSHCODE=$3

#PASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\%\^\&\(\)-+= < /dev/urandom | head -c 12)
DBPASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 12)
DB=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 5)
IP=$(wget -O - -q ifconfig.me)

if [ ! -d "/home/admin/web/$DOMAIN/public_html" ]; then
v-add-web-domain admin $DOMAIN $IP yes www.$DOMAIN
v-add-letsencrypt-domain admin $DOMAIN www.$DOMAIN
fi
if [ "$SCRIPT" = "wowonder" ]; then
v-change-web-domain-backend-tpl admin $DOMAIN PHP-7_2
fi

echo "$IP  $DOMAIN" >> /etc/hosts
v-add-database admin $DB $DB $DBPASSWD

cd /home/admin/web/$DOMAIN/public_html
rm -fr /home/admin/web/$DOMAIN/public_html/{*,.*} &> /dev/null
wget http://ss.ultahost.com/$SCRIPT.zip
unzip -qo $SCRIPT.zip
chmod 777 ffmpeg/ffmpeg upload cache ffmpeg/ffmpeg sys/ffmpeg/ffmpeg ./assets/import/ffmpeg/ffmpeg  &> /dev/null
chown -R admin:admin ./

 if [ "$SCRIPT" = "pixelphoto" ]; then
  mv ./install/index.php ./install.php_old
  wget https://raw.githubusercontent.com/it-toppp/ultahost/main/scripts/pixelphoto/installer.php -O ./install/index.php
 fi

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

#wowonder,playtube,deepsound
     mysql admin_$DB -e "UPDATE config SET value = 'on' WHERE  name = 'ffmpeg_system';" &> /dev/null
     mysql admin_$DB -e "UPDATE config SET value = '/usr/bin/ffmpeg' WHERE  name = 'ffmpeg_binary_file';" &> /dev/null

#pixelphoto
     mysql admin_$DB -e "UPDATE pxp_config SET value = 'on' WHERE  name = 'ffmpeg_sys';" &> /dev/null
     mysql admin_$DB -e "UPDATE pxp_config SET value = '/usr/bin/ffmpeg' WHERE  name = 'ffmpeg_binary_file';" &> /dev/null

#quickdate
     mysql admin_$DB -e "UPDATE options SET option_value = '1' WHERE  option_name = 'ffmpeg_sys';" &> /dev/null
     mysql admin_$DB -e "UPDATE options SET option_value = '/usr/bin/ffmpeg' WHERE option_name = 'ffmpeg_binary';" &> /dev/null

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
"
else
  echo Script $SCRIPT dont installed
fi
