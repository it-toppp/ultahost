#!/bin/bash

DOMAIN=$1
PASSWD=$2
SCRIPT=$3
PURSHCODE=$4
CPUSER=admin
DBPASSWD=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 12)
DB=$(LC_CTYPE=C tr -dc a-z0-9 < /dev/urandom | head -c 5)
#DB=$(echo $DOMAIN | tr -dc "a-z" | cut -c 1-5)
IP=$(wget -O - -q ifconfig.me)
DIG_IP=$(getent ahostsv4 $DOMAIN | sed -n 's/ *STREAM.*//p')

hostnamectl set-hostname cp.$DOMAIN
echo "$IP  $DOMAIN" >> /etc/hosts
yum -y remove NetworkManager
cd /home && curl -o latest -L https://securedownloads.cpanel.net/latest && sh latest
if /usr/local/cpanel/cpkeyclt  | grep -o -e "Update Failed" ; then
      echo 'Fail'
      exit
fi

wget https://raw.githubusercontent.com/it-toppp/Swap/master/swap.sh -O swap && sh swap 2048
yum localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm -y
yum install mc htop ffmpeg ffmpeg-devel ea-php80-php-zip ea-php74-php-zip ea-php73-php-zip -y
echo 'sql_mode=NO_ENGINE_SUBSTITUTION' >> /etc/my.cnf && systemctl restart mysqld
curl -sL https://rpm.nodesource.com/setup_14.x | sudo -E bash -
yum -y install nodejs
npm insrall forever -g

/scripts/install_lets_encrypt_autossl_provider
/usr/local/cpanel/scripts/setupftpserver --force pure-ftpd

#mysql
whmapi1 start_background_mysql_upgrade version=10.3

mkdir /var/cpanel/ApachePHPFPM
touch /var/cpanel/ApachePHPFPM/system_pool_defaults.yaml

#php_fpm
cat > /var/cpanel/ApachePHPFPM/system_pool_defaults.yaml << HERE
php_admin_value_disable_functions : passthru,system
pm.max_children : 100
HERE
/scripts/php_fpm_config --rebuild
/scripts/restartsrv_apache_php_fpm


#php_ini
whmapi1 php_ini_set_directives directive-1=memory_limit:1024M version=ea-php80
whmapi1 php_ini_set_directives directive-1=max_execution_time:6000 version=ea-php80
whmapi1 php_ini_set_directives directive-1=max_input_time:6000 version=ea-php80
whmapi1 php_ini_set_directives directive-1=post_max_size:5120M version=ea-php80
whmapi1 php_ini_set_directives directive-1=upload_max_filesize:5120M version=ea-php80
whmapi1 php_ini_set_directives directive-1=allow_url_fopen:On version=ea-php80
whmapi1 php_ini_set_directives directive-1=zlib.output_compression:Off version=ea-php80
whmapi1 php_ini_set_directives directive-1=memory_limit:1128M version=ea-php80

whmapi1 php_ini_set_directives directive-1=memory_limit:1024M version=ea-php74
whmapi1 php_ini_set_directives directive-1=max_execution_time:6000 version=ea-php74
whmapi1 php_ini_set_directives directive-1=max_input_time:6000 version=ea-php74
whmapi1 php_ini_set_directives directive-1=post_max_size:5120M version=ea-php74
whmapi1 php_ini_set_directives directive-1=upload_max_filesize:5120M version=ea-php74
whmapi1 php_ini_set_directives directive-1=allow_url_fopen:On version=ea-php74
whmapi1 php_ini_set_directives directive-1=zlib.output_compression:Off version=ea-php74
whmapi1 php_ini_set_directives directive-1=memory_limit:1128M version=ea-php74

whmapi1 php_ini_set_directives directive-1=memory_limit:1024M version=ea-php73
whmapi1 php_ini_set_directives directive-1=max_execution_time:6000 version=ea-php73
whmapi1 php_ini_set_directives directive-1=max_input_time:6000 version=ea-php73
whmapi1 php_ini_set_directives directive-1=post_max_size:5120M version=ea-php73
whmapi1 php_ini_set_directives directive-1=upload_max_filesize:5120M version=ea-php73
whmapi1 php_ini_set_directives directive-1=allow_url_fopen:On version=ea-php73
whmapi1 php_ini_set_directives directive-1=zlib.output_compression:Off version=ea-php73
whmapi1 php_ini_set_directives directive-1=memory_limit:1280M version=ea-php73

#whmapi1 createacct username=admin domain=$DOMAIN bwlimit=unlimited cgi=1 contactemail=admin@$DOMAIN cpmod=paper_lantern customip=192.0.2.0 dkim=1 featurelist=feature_list forcedns=0 frontpage=0 gid=123456789 hasshell=0 hasuseregns=1 homedir=/home/user ip=n language=en owner=root mailbox_format=mdbox max_defer_fail_percentage=unlimited max_email_per_hour=unlimited max_emailacct_quota=1024 maxaddon=unlimited maxftp=unlimited maxlst=unlimited maxpark=unlimited maxpop=unlimited maxsql=unlimited maxsub=unlimited mxcheck=auto password=123456 luggage pkgname=my_new_package plan=default quota=1024 reseller=0 savepkg=1 spamassassin=1 spf=1 spambox=y uid=123456789 useregns=1
whmapi1 createacct username=admin domain=${DOMAIN} password=${PASSWD}
uapi Mysql create_database name=$CPUSER_$DB --user $CPUSER 1>/dev/null
uapi Mysql create_user name=$CPUSER_$DB password=byrfgcekzwbz --user $CPUSER 1>/dev/null
uapi Mysql set_privileges_on_database user=$CPUSER_$DB database=$CPUSER_$DB privileges=ALL%20PRIVILEGES --user $CPUSER 1>/dev/null

echo "Full installation completed [ OK ]"
#chown admin:admin /home/admin/public_html

if [ ! -z "$SCRIPT" ]; then
curl -O https://raw.githubusercontent.com/it-toppp/ultahost/main/scripts/scriptsun.sh && bash scriptsun.sh $DOMAIN $SCRIPT $PURSHCODE
fi

whmapi1 --output=jsonpretty \
  php_set_vhost_versions \
  version='ea-php80' \
  vhost='otherchars.rm3.tld'

echo '======================================================='
echo -e "         
WHM:
    https://cp.$DOMAIN:2087
    username: root
    password: $PASSWD

Cpanel:
   https://cp.$DOMAIN:2083
   username: admin
   password: $PASSWD

SSH:
   host: $IP
   username: root
   password: $PASSWD
     
DB:
   db_name: $CPUSER_$DB
   db_user: $CPUSER_$DB
   db_pass: $DBPASSWD
" | tee -a /root/.admin
cd /root && rm -Rf hestiacp.sh scriptsun.sh
history -c
