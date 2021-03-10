#!/bin/bash
cd /usr/local/hestia/web/fm
rm index.php 
#tinyfilemanager.php config.php
wget https://raw.githubusercontent.com/it-toppp/ultahost/main/fm/index.php
if [ ! -f tinyfilemanager.php ]; then
wget https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php
chmod 666 tinyfilemanager.php
fi
if [ ! -f config.php ]; then
wget https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/config.php
chmod 644 config.php
fi
if [ ! -f translation.json ]; then
wget https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/translation.json
chmod 644 translation.json
fi

#conf
sed -i.bak -e "s/\$root\_path = \$\_SERVER\['DOCUMENT_ROOT'\];/\$root_path = \'\/home\/admin\/web\';/g" config.php
sed -i 's|max_upload_size_bytes = 2048|max_upload_size_bytes = 10000000000|' config.php
sed -i 's|"show_hidden":false|"show_hidden":true|' tinyfilemanager.php
sed -i "s|.*navbar-brand.*|        <a class="navbar-brand" href=\"/\"> Exit </a>|" tinyfilemanager.php
sed -i 's|use_auth = true|use_auth = false|' config.php
#sed -i "s|theme = 'light'|theme = \'dark\'|" config.php

#nginx
sed -i 's|client_max_body_size            256m|client_max_body_size  5120m|' /usr/local/hestia/nginx/conf/nginx.conf
sed -i 's|proxy_send_timeout              180|proxy_send_timeout  1200|' /usr/local/hestia/nginx/conf/nginx.conf
sed -i 's|proxy_read_timeout              300|proxy_read_timeout  1200|' /usr/local/hestia/nginx/conf/nginx.conf

#php
grep -rl  "_time] = 300" /usr/local/hestia/php/etc/ | xargs perl -p -i -e 's/_time] = 300/_time] = 1200/g'
sed -i 's|\[post_max_size\] = 256M|\[post_max_size\] = 5120M|' /usr/local/hestia/php/etc/php-fpm.conf
sed -i 's|\[upload_max_filesize\] = 256M|\[upload_max_filesize\] = 5120M|' /usr/local/hestia/php/etc/php-fpm.conf
systemctl restart hestia

#chown root:admin config.php tinyfilemanager.php
#chmod 660 config.php tinyfilemanager.php
