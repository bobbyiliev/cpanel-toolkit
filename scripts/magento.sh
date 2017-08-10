#!/bin/bash

function mage2_install_cloud() {
	MagentoChangePHPto5.6
        echo "This is probably the quickest way of deploying Magento 2 files on the Cloud"
        echo "Please note that you would still need to create a Database and a Database User!"
        echo ""
        unset empty
        while [ -z $empty ]; do
                echo "Is the public_html folder empty?[yes/no]"
                read empty
                echo "Are you 100% sure that the public_html folder is empty?"
                read empty
                if [ ! $empty == yes ]; then
                echo "Make sure that the public_html folder is empty before installing Magento!"
                exit 0
                fi
        done
    cd ~/public_html
        wget http://wpcli.bobbyiliev.com/magento2/Magento-CE-2.1.7-2017-05-30-01-54-40.tar.gz
        echo "Extracting magento files ... This might take a while, go make yourself a cup of coffee!"
        echo "Also go ahead and create a database, you would need it once the files have been uploaded!"
        tar -xzf Magento-CE-2.1.7-2017-05-30-01-54-40.tar.gz

        echo "CheckSpelling Off" >> ~/.htaccess
        echo "Magento 2 files have been deployed at $(pwd) visit the site and complete the installation!"
        echo "IMPORTANT!!! Under the advanced settings tab make sure that you select DB as the session handler otherwise your install will fail!"
}

mage2_install_cloud
