#!/bin/sh

# If you would like to do some extra provisioning you may
# add any commands you wish to this file and they will
# be run after the Homestead machine is provisioned.

# This script is compatible with "laravel/homestead": "^3.0"

# Change OUTPUT to /dev/stdout to see shell output while provisioning.
OUTPUT=/dev/stdout

echo ">>> Switching php version to 7.1"
sudo update-alternatives --set php /usr/bin/php7.1

echo ">>> Beginning DreamFactory provisioning..."
sudo apt-get update -qq -y

echo ">>> Installing postfix for local email service"
echo "postfix postfix/mailname string mail.example.com" | debconf-set-selections
echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postfix > $OUTPUT 2>&1

echo ">>> Installing php mongodb extension"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -qq -y php7.1-mongodb > $OUTPUT 2>&1

echo ">>> Installing phpMyAdmin (http://host/pma)"
cd */.
composer create-project phpmyadmin/phpmyadmin --repository-url=https://www.phpmyadmin.net/packages.json --no-dev public/pma > $OUTPUT 2>&1

echo ">>> Setting up workbench for some packages";
mkdir -p workbench/repos > $OUTPUT 2>&1
cd workbench/repos
echo ">>> ----> Cloning df-user";
git clone -b role_access_fix https://github.com/x-dreamfactory/df-user.git > $OUTPUT 2>&1
cd ../../
php -r 'strpos(file_get_contents("composer.json"), "User\\\\\":") === false && file_put_contents("composer.json", str_replace("\"DreamFactory\\\\\": \"app/\",", "\"DreamFactory\\\\\": \"app/\",\n      \"DreamFactory\\\\Core\\\\User\\\\\": \"workbench/repos/df-user/src/\",", file_get_contents("composer.json")));'
composer dump-autoload > $OUTPUT 2>&1

echo ">>> Installing workbench git tools"
cp server/config/homestead/tools/*.php workbench/repos/

echo ">>> Create database (df_unit_test) for unit test"
mysql -e "CREATE DATABASE IF NOT EXISTS \`df_unit_test\` DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_unicode_ci";

echo ">>> Setting up dreamfactory .env with homestead mysql database"
sudo php artisan cache:clear
sudo php artisan config:clear
sudo php artisan clear-compiled
cp .env .env-backup-homestead > $OUTPUT 2>&1
rm .env > $OUTPUT 2>&1
php artisan df:env --db_connection=mysql --db_host=127.0.0.1 --db_database=homestead --db_username=homestead --db_password=secret > $OUTPUT 2>&1

cd ../
echo ">>> Installing 'zip' command"
sudo apt-get install -qq -y zip > $OUTPUT 2>&1

echo ">>> Installing Python bunch"
sudo pip install bunch > $OUTPUT 2>&1

echo ">>> Installing Node.js lodash"
sudo npm install lodash > $OUTPUT 2>&1

echo ">>> Configuring XDebug"
printf "xdebug.remote_enable=1\nxdebug.remote_connect_back=1\nxdebug.max_nesting_level=512" | sudo tee -a /etc/php/7.0/mods-available/xdebug.ini > $OUTPUT 2>&1

echo ">>> Configuring NGINX to allow editing .php file using storage services."
sudo php -r 'file_put_contents("/etc/nginx/sites-available/homestead.localhost", str_replace("location ~ \.php$ {", "location ~ \.php$ {\n        try_files  "."$"."uri rewrite ^ /index.php?"."$"."query_string;", file_get_contents("/etc/nginx/sites-available/homestead.localhost")));'

sudo service php7.1-fpm restart
sudo service nginx restart

echo ">>> Provisioning complete. Launch your instance."
