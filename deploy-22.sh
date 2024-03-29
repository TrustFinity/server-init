#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Check if user is root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

# Configure
MYSQL_ROOT_PASSWORD="deployer"
MYSQL_NORMAL_USER="deployer"
MYSQL_NORMAL_USER_PASSWORD="deployer"

# Check if password is defined
if [[ "$MYSQL_ROOT_PASSWORD" == "" ]]; then
    echo "${CFAILURE}Error: MYSQL_ROOT_PASSWORD not define!!${CEND}";
    exit 1;
fi
if [[ "$MYSQL_NORMAL_USER_PASSWORD" == "" ]]; then
    echo "${CFAILURE}Error: MYSQL_NORMAL_USER_PASSWORD not define!!${CEND}";
    exit 1;
fi


# Add user and group deployer
echo "Adding deployer user and group"
useradd -d /home/deployer -c "deployer data" -m -s /bin/bash deployer
usermod -aG sudo deployer

# Update Package List
apt-get update

# Update System Packages
apt-get -y upgrade

# remove apache2
apt purge apache2 -y

# Install Some PPAs
apt-get install -y software-properties-common curl

apt-add-repository ppa:nginx/development -y
apt-add-repository ppa:chris-lea/redis-server -y
apt-add-repository ppa:ondrej/php -y

# Using the default Ubuntu 16 MySQL 7 Build
gpg: key 5072E1F5: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 5072E1F5
sh -c 'echo "deb http://repo.mysql.com/apt/ubuntu/ xenial mysql-5.7" >> /etc/apt/sources.list.d/mysql.list'

# Install node
curl --silent --location https://deb.nodesource.com/setup_18.x | bash -

# Update Package Lists
apt-get update

# Install Some Basic Packages
apt-get install -y build-essential dos2unix gcc git libmcrypt4 libpcre3-dev \
make python python-pip re2c supervisor unattended-upgrades whois vim libnotify-bin

# Install PHP8.1 Stuffs
apt-get install -y --force-yes php8.1-cli php8.1 \
php8.1-gd php8.1-curl php8.1-mcrypt \
php8.1-mysql php8.1-xdebug php8.1-mbstring php8.1-xml php8.1-zip php8.1-bcmath \
php8.1-dom

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Add Composer Global Bin To Path
printf "\nPATH=\"$(composer config -g home 2>/dev/null)/vendor/bin:\$PATH\"\n" | tee -a ~/.profile

# Set Some PHP CLI Settings
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/8.1/cli/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/8.1/cli/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/8.1/cli/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/8.1/cli/php.ini

# Install Nginx & PHP-FPM
apt-get install -y --force-yes nginx php8.1-fpm

# Setup Some PHP-FPM Options
sed -i "s/error_reporting = .*/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/" /etc/php/8.1/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/8.1/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/8.1/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/8.1/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 50M/" /etc/php/8.1/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 50M/" /etc/php/8.1/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/8.1/fpm/php.ini
sed -i "s/listen =.*/listen = 127.0.0.1:9000/" /etc/php/8.1/fpm/pool.d/www.conf

# Setup Some fastcgi_params Options
cat > /etc/nginx/fastcgi_params << EOF
fastcgi_param	QUERY_STRING		\$query_string;
fastcgi_param	REQUEST_METHOD		\$request_method;
fastcgi_param	CONTENT_TYPE		\$content_type;
fastcgi_param	CONTENT_LENGTH		\$content_length;
fastcgi_param	SCRIPT_FILENAME		\$request_filename;
fastcgi_param	SCRIPT_NAME		\$fastcgi_script_name;
fastcgi_param	REQUEST_URI		\$request_uri;
fastcgi_param	DOCUMENT_URI		\$document_uri;
fastcgi_param	DOCUMENT_ROOT		\$document_root;
fastcgi_param	SERVER_PROTOCOL		\$server_protocol;
fastcgi_param	GATEWAY_INTERFACE	CGI/1.1;
fastcgi_param	SERVER_SOFTWARE		nginx/\$nginx_version;
fastcgi_param	REMOTE_ADDR		\$remote_addr;
fastcgi_param	REMOTE_PORT		\$remote_port;
fastcgi_param	SERVER_ADDR		\$server_addr;
fastcgi_param	SERVER_PORT		\$server_port;
fastcgi_param	SERVER_NAME		\$server_name;
fastcgi_param	HTTPS			\$https if_not_empty;
fastcgi_param	REDIRECT_STATUS		200;
EOF

# Set The Nginx & PHP-FPM User
sed -i "s/user www-data;/user deployer;/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf
sed -i "s/user = www-data/user = deployer/" /etc/php/8.1/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = deployer/" /etc/php/8.1/fpm/pool.d/www.conf
sed -i "s/listen\.owner.*/listen.owner = deployer/" /etc/php/8.1/fpm/pool.d/www.conf
sed -i "s/listen\.group.*/listen.group = deployer/" /etc/php/8.1/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/8.1/fpm/pool.d/www.conf

service nginx restart
service php8.1-fpm restart

# Install Node
apt-get install -y nodejs npm

# Install MySQL
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password ${MYSQL_ROOT_PASSWORD}"
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password ${MYSQL_ROOT_PASSWORD}"
apt-get install -y mysql-server

# Configure MySQL Password Lifetime
echo "default_password_lifetime = 0" >> /etc/mysql/mysql.conf.d/mysqld.cnf
mysql --user="root" --password="${MYSQL_ROOT_PASSWORD}" -e "CREATE USER '${MYSQL_NORMAL_USER}'@'0.0.0.0' IDENTIFIED BY '${MYSQL_NORMAL_USER_PASSWORD}';"
mysql --user="root" --password="${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL ON *.* TO '${MYSQL_NORMAL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_NORMAL_USER_PASSWORD}' WITH GRANT OPTION;"
mysql --user="root" --password="${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL ON *.* TO '${MYSQL_NORMAL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_NORMAL_USER_PASSWORD}' WITH GRANT OPTION;"
mysql --user="root" --password="${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
service mysql restart

# Add Timezone Support To MySQL
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --user=root --password=${MYSQL_ROOT_PASSWORD} mysql

# Install A Few Other Things
apt-get install -y redis-server

# Configure Supervisor
service supervisor.service enable
service supervisor start

# Enable Swap Memory
/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=2048
/sbin/mkswap /var/swap.1
chmod 0600 /var/swap.1
/sbin/swapon /var/swap.1

# clear
echo "--"
echo "--"
echo "It's Done."
echo "Mysql Root Password: ${MYSQL_ROOT_PASSWORD}"
echo "Mysql Normal User: ${MYSQL_NORMAL_USER}"
echo "Mysql Normal User Password: ${MYSQL_NORMAL_USER_PASSWORD}"
echo "--"
echo "--"
