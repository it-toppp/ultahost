#!/bin/bash
#fix_templates
replace "== 'admin'" "== '0admin'" -- /usr/local/hestia/web/templates/pages/add_web.php
replace '== "admin"' '== "0admin"' -- /usr/local/hestia/web/templates/pages/add_web.php
replace "== 'admin'" "== '0admin'" -- /usr/local/hestia/web/templates/pages/add_db.php
replace '== "admin"' '== "0admin"' -- /usr/local/hestia/web/templates/pages/add_db.php
replace "== 'admin'" "== '0admin'" -- /usr/local/hestia/web/templates/pages/add_mail.php
replace '== "admin"' '== "0admin"' -- /usr/local/hestia/web/templates/pages/add_mail.php
replace "== 'admin'" "== '0admin'" -- /usr/local/hestia/web/templates/pages/add_dns.php
replace '== "admin"' '== "0admin"' -- /usr/local/hestia/web/templates/pages/add_dns.php

#PHP
grep -rl  "pm.max_children = 8" /etc/php /usr/local/hestia/data/templates/web/php-fpm | xargs perl -p -i -e 's/pm.max_children = 8/pm.max_children = 1000/g'
grep -rl  "php_admin_value\[open_basedir\]" /etc/php /usr/local/hestia/data/templates/web/php-fpm | xargs perl -p -i -e 's|php_admin_value\[open_basedir\]|;php_admin_value\[open_basedir\]|g'

#FIX FM
grep -rl "directoryPerm = 0744" /usr/local/hestia/web/fm/vendor/league/flysystem-sftp | xargs perl -p -i -e 's/directoryPerm = 0744/directoryPerm = 0755/g'

if grep "AltFileManager" /usr/local/hestia/web/templates/includes/panel.php; then
echo "pass"
else
cat > fm_tmp << HERE
                         <!-- File Manager -->
                                                <?php if (isset(\$_SESSION["FILE_MANAGER"]) && !empty(\$_SESSION["FILE_MANAGER"]) && \$_SESSION["FILE_MANAGER"] == "true") { ?>
                                                        <?php if (\$_SESSION["userContext"] === "admin" && (isset(\$_SESSION["look"]) && \$_SESSION["look"] === "admin" && \$_SESSION["POLICY_SYSTEM_PROTECTED_ADMIN"] == "yes")) { ?>
                                                                <!-- Hide file manager when impersonating admin-->
                                                        <?php } else { ?>
                                                                <li class="top-bar-menu-item">
                                                                        <a title="<?= _("AltFileManager") ?>" class="top-bar-menu-link <?php if(\$TAB == 'FM') echo 'active' ?>" href="/fm1/">
                                                                                <i class="fas fa-folder-open"></i>
                                                                                <span class="top-bar-menu-link-label u-hide-desktop"><?= _("AltFileManager") ?></span>
                                                                        </a>
                                                                </li>
                                                        <?php } ?>
                                                <?php } ?>

HERE
sed -i -e '/top-bar-menu-list/r fm_tmp' /usr/local/hestia/web/templates/includes/panel.php
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
#wget https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php
wget https://raw.githubusercontent.com/prasathmani/tinyfilemanager/2.4.7/tinyfilemanager.php
wget https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/translation.json
cat > /usr/local/hestia/web/fm1/config.php << HERE 
<?php
\$root_path = '/home/admin/web';
\$edit_files = true;
\$root_url = '';
\$override_file_name = true;
\$use_auth = false;
?>
HERE
chmod 644 config.php tinyfilemanager.php translation.json

sed -i 's|timeout: 120000,|timeout: 12000001,|' tinyfilemanager.php
sed -i 's|"show_hidden":false|"show_hidden":true|' tinyfilemanager.php
sed -i 's|override_file_name = false|override_file_name = true|' tinyfilemanager.php
sed -i "s|.*navbar-brand.*|        <a class="navbar-brand" href=\"/\"> Exit </a>|" tinyfilemanager.php
sed -i 's|use_auth = true|use_auth = false|' config.php

#hestia
sed -i 's|client_max_body_size.\+|client_max_body_size  10240m;|' /usr/local/hestia/nginx/conf/nginx.conf
sed -i 's|proxy_send_timeout.\+|proxy_send_timeout  1200;|' /usr/local/hestia/nginx/conf/nginx.conf
sed -i 's|proxy_read_timeout.\+|proxy_read_timeout  1200;|' /usr/local/hestia/nginx/conf/nginx.conf
grep -rl  "_time] = 300" /usr/local/hestia/php/etc/ | xargs perl -p -i -e 's/_time] = 300/_time] = 1200/g'
sed -i 's|\[post_max_size\] = 256M|\[post_max_size\] = 10240M|' /usr/local/hestia/php/etc/php-fpm.conf
sed -i 's|\[upload_max_filesize\] = 256M|\[upload_max_filesize\] = 10240M|' /usr/local/hestia/php/etc/php-fpm.conf
sed -i 's|php_admin_value\[open_basedir\]|;php_admin_value\[open_basedir\]|' /usr/local/hestia/php/etc/php-fpm.conf
systemctl restart hestia
