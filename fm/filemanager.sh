#!/bin/bash
cd /usr/local/hestia/web/fm
rm -f /usr/local/hestia/web/fm/index.php
wget https://raw.githubusercontent.com/it-toppp/ultahost/main/fm/index.php
if [ ! -f tinyfilemanager.php ]; then
wget https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php
fi
if [ ! -f config.php ]; then
wget https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/config.php
fi
if [ ! -f translation.json ]; then
wget https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/translation.json
fi
#nginx
sed -i 's|client_max_body_size            256m|client_max_body_size  5120m|' /usr/local/hestia/nginx/conf/nginx.conf
#sed -i 's|send_timeout                    60;|send_timeout  1200;|' /etc/nginx/nginx.conf
sed -i 's|proxy_send_timeout              180|proxy_send_timeout  1200|' /etc/nginx/nginx.conf
sed -i 's|proxy_read_timeout              300|proxy_read_timeout  1200|' /etc/nginx/nginx.conf

#php
sed -i 's|\[post_max_size\] = 256M|\[post_max_size\] = 5120M|' /usr/local/hestia/php/etc/php-fpm.conf
sed -i 's|\[upload_max_filesize\] = 256M|\[post_max_size\] = 5120M|' /usr/local/hestia/php/etc/php-fpm.conf
systemctl restart hestia
#conf
sed -i.bak -e "s/\$root\_path = \$\_SERVER\['DOCUMENT_ROOT'\];/\$root_path = \'\/home\/admin\';/g"    /usr/local/hestia/web/fm/config.php
