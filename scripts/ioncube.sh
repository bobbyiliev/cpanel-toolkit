#!/bin/bash

whichletter="$(pwd | awk -F/ '{print $4}')"
whichdomain="$(pwd | awk -F/ '{print $5}')"
ioncubedir="$(/var/sites/${whichletter}/${whichdomain}/ioncube)"

# Function to Download and extract 64-bit files
	clear
        echo -e "\n Downloading the ioncube archieve"
        wget -q https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz

# Extract the archieve
        sleep 2>/dev/null
        echo -e "\n Extracting archieve"
        tar xvf ioncube_loaders_lin_x86-64.tar.gz

# Detect the PHP version
        echo -e "\n Detect the PHP version"
        PHP_VER="$(command php --version | head -n 1 | cut --characters=5-7)"
        echo -e "\n PHP version is $PHP_VER"

# Create php.ini file
if grep -q "AddType x-httpd-php7 .php" ~/public_html/.htaccess 2>/dev/null
then
                echo "$(ColorGreen 'The current PHP version is 7')
                ";
                cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-7
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set $
created.')
";

                mv php.ini-7 php.ini
        if grep -q "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/.htaccess" ~/public_html/.htaccess 2>/dev/null
        then
               	echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
        else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_ht$
        fi
fi

# Add ioncube to php.ini
        echo -e "\n Adding ioncube to the php.ini"
	sed -i '/zend_extension=/c\/var/sites/${whichletter}/${whichdomain}/ioncube/ioncube_loader_lin_${PHP_VER}.so/g' php.ini
