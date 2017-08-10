#!/bin/bash

function install_ioncube_php70() {
        ColorGreen(){
            echo -ne $green$1$clear
        }

	ColorRed(){
	echo -ne $red$1$clear
	}

        green='\e[32m'
	red='\e[31m'
	clear='\e[0m'



        if ! grep -q "AddType x-httpd-php7" ~/.htaccess 2>/dev/null ; then
                echo $(ColorGreen  "This is only for PHP 7.0, and you are running a different PHP version!")
            #change to CloudMenu
            exit 0;
        fi

        whichletter="$(pwd | awk -F/ '{print $4}')"
        whichdomain="$(pwd | awk -F/ '{print $5}')"
        PHP_VER="$(if grep -q "AddType x-httpd-php7" ~/.htaccess 2>/dev/null ; then
           echo "7.0";
        fi
        )"


        # Function to Download and extract 64-bit files

        clear
            echo "$(ColorRed 'Downloading the ioncube archieve')";
                echo ""
            wget -q https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz


        # Extract the archieve
                sleep 2s
            echo "$(ColorGreen 'Extracting archieve')";
            echo ""
                tar xvf ioncube_loaders_lin_x86-64.tar.gz

        # Creating php.ini

        if grep -q "AddType x-httpd-php7 .php" ~/.htaccess 2>/dev/null
        then
                echo ""
            echo "$(ColorGreen 'The current PHP version is 7')
                           ";
                           cd ~/public_html/
                           mv php.ini php.ini-old 2>/dev/null
                           cd
                        mv php.ini php.ini-old 2>/dev/null
                        wget -q http://paragon.alexgeorgiev.net/phpini/php.ini-7
                           echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been set to 8000 
and
   	error_logging$
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
                        echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null
                   fi
        fi


        # Add ioncube to php.ini

            echo ""
            echo "$(ColorGreen 'Adding ioncube to the php.ini')";
            echo "" >> ~/php.ini 2>/dev/null
            echo -e "zend_extension_ts=/var/sites/${whichletter}/${whichdomain}/ioncube/ioncube_loader_lin_${PHP_VER}_ts.so" >> ~/php.ini 2>/dev/null
            echo -e "zend_extension=/var/sites/${whichletter}/${whichdomain}/ioncube/ioncube_loader_lin_${PHP_VER}.so" >> ~/php.ini 2>/dev/null
            echo ""
}
install_ioncube_php70
