#!/bin/bash
cd /usr/local/hestia/web/fm
rm -f /usr/local/hestia/web/fm/index.php
wget https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php
wget https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/translation.json
wget https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/config.php
wget https://raw.githubusercontent.com/it-toppp/ultahost/main/fm/index.php
#nginx
sed -i 's|client_max_body_size            256m|client_max_body_size  5120m|' /usr/local/hestia/nginx/conf/nginx.conf
#php
sed -i 's|\[post_max_size\] = 256M|\[post_max_size\] = 5120M|' /usr/local/hestia/php/etc/php-fpm.conf
sed -i 's|\[upload_max_filesize\] = 256M|\[post_max_size\] = 5120M|' /usr/local/hestia/php/etc/php-fpm.conf
systemctl restart hestia
#conf
sed -i.bak -e "s/\$root\_path = \$\_SERVER\['DOCUMENT_ROOT'\];/\$root_path = \'\/home\/admin\';/g"    /usr/local/hestia/web/fm/config.php
