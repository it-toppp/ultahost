#!/bin/bash
DOMAIN=$1
SCRIPT=$2
PURSHCODE=$3
user=admin
WORKINGDIR="/home/$user/web/$DOMAIN/public_html"
#PASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\%\^\&\(\)-+= < /dev/urandom | head -c 12)
DBPASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 12)
DB=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 5)
DBNAME=$user"_"$DB
DBUSER=$DBNAME
IP=$(wget -O - -q ifconfig.me)
email=admin@$DOMAIN

echo "$IP  $DOMAIN" >> /etc/hosts
v-add-database $user $DB $DB $DBPASSWD

if [ ! -d "/home/$user/web/$DOMAIN/public_html" ]; then
v-add-web-domain $user $DOMAIN $IP yes www.$DOMAIN
v-add-letsencrypt-domain $user $DOMAIN www.$DOMAIN
fi

if [ ! -f "/home/$user/conf/web/$DOMAIN/ssl/$DOMAIN.pem" ]; then
    v-add-letsencrypt-domain $user "$DOMAIN" "www.$DOMAIN"
    v-schedule-letsencrypt-domain $user $DOMAIN www.$DOMAIN
fi

if [ "$SCRIPT" = "wowonder-null" ] || [ "$SCRIPT" = "wowonder" ]; then
v-change-web-domain-backend-tpl $user $DOMAIN PHP-8_0
fi

cd $WORKINGDIR
rm -fr $WORKINGDIR/{*,.*} &> /dev/null

function wordpress() {
rm -rf /home/$user/wp
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /home/$user/wp
cd /home/$user/web/$DOMAIN/public_html
/home/$user/wp core download --allow-root
/home/$user/wp core config --dbname=$DBNAME --dbuser=$DBUSER --dbpass=$DBPASSWD --allow-root
/home/$user/wp core install --url="$DOMAIN" --title="$DOMAIN" --admin_user=admin --admin_password="$DBPASSWD" --admin_email="$email" --path=$WORKINGDIR --allow-root
#FIX za https://github.com/wp-cli/wp-cli/issues/2632
mysql -u$DBUSER -p$DBPASSWD $DBNAME -e "update wp_options set option_value = 'https://$DOMAIN' where option_name = 'siteurl'; update wp_options set option_value = 'https://$DOMAIN' where option_name = 'home';"
chown -R $user:$user $WORKINGDIR
rm -rf /home/$user/wp

cat >> .htaccess <<EOF
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
EOF

}

function scriptsun() {
chown -R $user:$user ./
chmod 777 ffmpeg/ffmpeg upload cache ffmpeg/ffmpeg sys/ffmpeg/ffmpeg ./assets/import/ffmpeg/ffmpeg  &> /dev/null
curl -L --fail --silent --show-error --post301 --insecur \
     --data-urlencode "purshase_code=$PURSHCODE" \
     --data-urlencode "sql_host=localhost" \
     --data-urlencode "sql_user=$DBUSER" \
     --data-urlencode "sql_pass=$DBPASSWD" \
     --data-urlencode "sql_name=$DBNAME" \
     --data-urlencode "site_url=https://$DOMAIN" \
     --data-urlencode "siteName=$DOMAIN" --data-urlencode "site_name=$DOMAIN" \
     --data-urlencode "siteTitle=$DOMAIN" --data-urlencode "site_title=$DOMAIN" \
     --data-urlencode "siteEmail=info@$DOMAIN" --data-urlencode "site_email=admin@$DOMAIN" \
     --data-urlencode "admin_username=admin" \
     --data-urlencode "admin_password=$DBPASSWD" \
     --data-urlencode "install=install" \
http://$DOMAIN/install/?page=installation | grep -o -e "Failed to connect to MySQL" -e "successfully installed" -e "Wrong purchase code" -e "This code is already used on another domain"
}

#pixelphoto
if [ "$SCRIPT" = "pixelphoto" ]; then
  wget http://ss.ultahost.com/$SCRIPT.zip && unzip -qo $SCRIPT.zip
  rm -f ./install/index.php
  wget https://raw.githubusercontent.com/it-toppp/ultahost/main/scripts/pixelphoto/installer.php -O ./install/index.php
  scriptsun
  mysql $DBNAME -e "UPDATE pxp_config SET value = 'on' WHERE  name = 'ffmpeg_sys';" &> /dev/null
  mysql $DBNAME -e "UPDATE pxp_config SET value = '/usr/bin/ffmpeg' WHERE  name = 'ffmpeg_binary_file';" &> /dev/null
fi


#wowonder
if [ "$SCRIPT" = "wowonder" ] ; then
    wget http://ss.ultahost.com/$SCRIPT.zip && unzip -qo $SCRIPT.zip "Script/*" && mv Script\/{*,.*} ./ &> /dev/null
    scriptsun
    mysql $DBNAME -e "UPDATE Wo_Config SET value = 'on' WHERE  name = 'ffmpeg_system';" &> /dev/null
    mysql $DBNAME -e "UPDATE Wo_Config SET value = '/usr/bin/ffmpeg' WHERE  name = 'ffmpeg_binary_file';" &> /dev/null
    mysql $DBNAME -e "UPDATE Wo_Config SET value = '2053' WHERE  name = 'nodejs_ssl_port';" &> /dev/null
    mysql $DBNAME -e "UPDATE Wo_Config SET value = '1' WHERE  name = 'node_socket_flow';" &> /dev/null
    mysql $DBNAME -e "UPDATE Wo_Config SET value = '1' WHERE  name = 'nodejs_ssl';" &> /dev/null
    mysql $DBNAME -e "UPDATE Wo_Config SET value = '1' WHERE  name = 'nodejs_live_notification';" &> /dev/null
    mysql $DBNAME -e "UPDATE Wo_Config SET value = '/home/$user/conf/web/$DOMAIN/ssl/$DOMAIN.key' WHERE  name = 'nodejs_key_path';" &> /dev/null
    mysql $DBNAME -e "UPDATE Wo_Config SET value = '/home/$user/conf/web/$DOMAIN/ssl/$DOMAIN.crt' WHERE  name = 'nodejs_cert_path';" &> /dev/null
    v-add-firewall-rule ACCEPT 0.0.0.0/0 2053
    cd /home/$user/web/$DOMAIN/public_html/nodejs
    npm install
    pm2 delete wowonder &> /dev/null
    pm2 start main.js --name "wowonder"
    pm2 startup
    pm2 save    
fi

#playtube,deepsound,flame
if [ "$SCRIPT" = "playtube" ] || [ "$SCRIPT" = "deepsound" ]|| [ "$SCRIPT" = "flame" ]; then
    wget http://ss.ultahost.com/$SCRIPT.zip && unzip -qo $SCRIPT.zip "Script/*" && mv Script\/{*,.*} ./ &> /dev/null
    scriptsun
    mysql $DBNAME -e "UPDATE config SET value = 'on' WHERE  name = 'ffmpeg_system';" &> /dev/null
    mysql $DBNAME -e "UPDATE config SET value = '/usr/bin/ffmpeg' WHERE  name = 'ffmpeg_binary_file';" &> /dev/null  
fi

#quickdate
if [ "$SCRIPT" = "quickdate" ]; then
     wget http://ss.ultahost.com/$SCRIPT.zip && unzip -qo $SCRIPT.zip
     scriptsun
     mysql $DBNAME -e "UPDATE options SET option_value = '1' WHERE  option_name = 'ffmpeg_sys';" &> /dev/null
     mysql $DBNAME -e "UPDATE options SET option_value = '/usr/bin/ffmpeg' WHERE option_name = 'ffmpeg_binary';" &> /dev/null
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

if grep -wqorP $DBNAME /home/$user/web/$DOMAIN/public_html; then
    rm -r ./install  __MACOSX $SCRIPT.zip  &> /dev/null

    echo -e "Installation $SCRIPT is successfully:
    https://$DOMAIN
    username: admin
    password: $DBPASSWD
" | tee -a /root/.admin
else
  echo Script $SCRIPT dont installed
fi
