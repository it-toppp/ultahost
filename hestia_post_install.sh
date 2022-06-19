#!/bin/bash
#fix_templates
replace "== 'admin'" "== '0admin'" -- /usr/local/hestia/web/templates/pages/add_web.html
replace '== "admin"' '== "0admin"' -- /usr/local/hestia/web/templates/pages/add_web.html
replace "== 'admin'" "== '0admin'" -- /usr/local/hestia/web/templates/pages/add_db.html
replace '== "admin"' '== "0admin"' -- /usr/local/hestia/web/templates/pages/add_db.html
replace "== 'admin'" "== '0admin'" -- /usr/local/hestia/web/templates/pages/add_mail.html
replace '== "admin"' '== "0admin"' -- /usr/local/hestia/web/templates/pages/add_mail.html
replace "== 'admin'" "== '0admin'" -- /usr/local/hestia/web/templates/pages/add_dns.html
replace '== "admin"' '== "0admin"' -- /usr/local/hestia/web/templates/pages/add_dns.html

#PHP
grep -rl  "pm.max_children = 8" /etc/php /usr/local/hestia/data/templates/web/php-fpm | xargs perl -p -i -e 's/pm.max_children = 8/pm.max_children = 1000/g'
grep -rl  "php_admin_value\[open_basedir\]" /etc/php /usr/local/hestia/data/templates/web/php-fpm | xargs perl -p -i -e 's|php_admin_value\[open_basedir\]|;php_admin_value\[open_basedir\]|g'

#FIX FM
grep -rl "directoryPerm = 0744" /usr/local/hestia/web/fm/vendor/league/flysystem-sftp | xargs perl -p -i -e 's/directoryPerm = 0744/directoryPerm = 0755/g'

if grep "FileManager" /usr/local/hestia/web/templates/includes/panel.html; then
echo "pass"
else
cat > fm_tmp << HERE
                                <!-- FileManagerAlt -->
                  <?php if ((\$_SESSION['userContext'] === 'admin') && (\$_SESSION['POLICY_SYSTEM_HIDE_SERVICES'] !== 'yes') || (\$_SESSION['user'] === 'admin')) {?>
                                <?php if ((\$_SESSION['userContext'] === 'admin') && (!empty(\$_SESSION['look']))) {?>
                                        <!-- Hide 'Server Settings' button when impersonating 'admin' or other users -->
                                <?php } else { ?>
                        <?php if ((isset(\$_SESSION['FILE_MANAGER'])) && (!empty(\$_SESSION['FILE_MANAGER'])) && (\$_SESSION['FILE_MANAGER'] == "true")) {?>
                                <?php if ((\$_SESSION['userContext'] === 'admin') && (isset(\$_SESSION['look']) && (\$_SESSION['look'] === 'admin') && (\$_SESSION['POLICY_SYSTEM_PROTECTED_ADMIN'] == 'yes'))) {?>
                                                <!-- Hide file manager when impersonating admin-->
                                        <?php } else { ?>
                                                <div class="l-menu__item <?php if(\$TAB == 'FM') echo 'l-menu__item--active' ?>"><a href="/fm1/"><i class="fas fa-folder-open panel-icon"></i><?=_('FileManager');?></a></div>
                                <?php } ?>
                        <?php } ?>
            <?php } ?>
<?php } ?>
<!-- File Manager -->
HERE
sed -i -e '/File Manager tab/r fm_tmp' /usr/local/hestia/web/templates/includes/panel.html
rm -f fm_tmp
fi

rm -rf mkdir /usr/local/hestia/web/fm1 2>/dev/null
mkdir /usr/local/hestia/web/fm1
cd /usr/local/hestia/web/fm1
cat > index.php << HERE
<?php
error_reporting(NULL);
\$TAB = 'USER';
include(\$_SERVER['DOCUMENT_ROOT']."/inc/main.php");
define('FM_EMBED', true);
define('FM_SELF_URL', \$_SERVER['PHP_SELF']);
require 'tinyfilemanager.php';
\$_SESSION['back'] = \$_SERVER['REQUEST_URI'];
HERE
wget https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php
wget https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/config-sample.php -O config.php
wget https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/translation.json
chmod 644 config.php tinyfilemanager.php translation.json
sed -i.bak -e "s/\$root\_path = \$\_SERVER\['DOCUMENT_ROOT'\];/\$root_path = \'\/home\/admin\/web\';/g" config.php
sed -i 's|max_upload_size_bytes = 2048|max_upload_size_bytes = 10000000000|' config.php
sed -i 's|timeout: 120000,|timeout: 12000001,|' tinyfilemanager.php
sed -i 's|"show_hidden":false|"show_hidden":true|' tinyfilemanager.php
sed -i "s|.*navbar-brand.*|        <a class="navbar-brand" href=\"/\"> Exit </a>|" tinyfilemanager.php
sed -i 's|use_auth = true|use_auth = false|' config.php
#sed -i "s|theme = 'light'|theme = \'dark\'|" config.php

#hestia
sed -i 's|client_max_body_size.\+|client_max_body_size  10240m;|' /usr/local/hestia/nginx/conf/nginx.conf
sed -i 's|proxy_send_timeout.\+|proxy_send_timeout  1200;|' /usr/local/hestia/nginx/conf/nginx.conf
sed -i 's|proxy_read_timeout.\+|proxy_read_timeout  1200;|' /usr/local/hestia/nginx/conf/nginx.conf
grep -rl  "_time] = 300" /usr/local/hestia/php/etc/ | xargs perl -p -i -e 's/_time] = 300/_time] = 1200/g'
sed -i 's|\[post_max_size\] = 256M|\[post_max_size\] = 10240M|' /usr/local/hestia/php/etc/php-fpm.conf
sed -i 's|\[upload_max_filesize\] = 256M|\[upload_max_filesize\] = 10240M|' /usr/local/hestia/php/etc/php-fpm.conf
sed -i 's|php_admin_value\[open_basedir\]|;php_admin_value\[open_basedir\]|' /usr/local/hestia/php/etc/php-fpm.conf
systemctl restart hestia
