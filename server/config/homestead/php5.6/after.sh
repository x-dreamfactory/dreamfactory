#!/bin/sh

# If you would like to do some extra provisioning you may
# add any commands you wish to this file and they will
# be run after the Homestead machine is provisioned.

sudo apt-get -qq update > afterScriptLog.txt

echo ">>> Installing php-ldap extension"

sudo apt-get install -qq -y php5-ldap > afterScriptLog.txt

echo ">>> Installing mongodb driver"

sudo apt-get install -qq -y autoconf g++ make openssl libssl-dev libcurl4-openssl-dev > afterScriptLog.txt
sudo apt-get install -qq -y libcurl4-openssl-dev pkg-config > afterScriptLog.txt
sudo apt-get install -qq -y libsasl2-dev > afterScriptLog.txt
sudo pecl install mongodb > afterScriptLog.txt
sudo echo "extension=mongodb.so" > /etc/php5/mods-available/mongodb.ini
sudo ln -s /etc/php5/mods-available/mongodb.ini /etc/php5/cli/conf.d/99-mongodb.ini
sudo ln -s /etc/php5/mods-available/mongodb.ini /etc/php5/fpm/conf.d/99-mongodb.ini
sudo service php5-fpm restart
sudo service nginx restart

echo ">>> Setting up dreamfactory with homestead mysql database"

cd */.
sudo php artisan cache:clear
sudo php artisan config:clear
sudo php artisan clear-compiled
cp .env .env-backup-homestead
rm .env
php artisan dreamfactory:setup --db_driver=mysql --db_host=127.0.0.1 --db_database=homestead --db_username=homestead --db_password=secret --cache_driver=file

echo ">>> Setup complete."
