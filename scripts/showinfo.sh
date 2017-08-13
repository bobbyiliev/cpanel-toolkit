#!/bin/bash
#!/bin/bash
###################
###  Variables  ###
###################
green='\e[32m'
blue='\e[34m'
clear='\e[0m'
red='\e[31m'
ColorGreen(){
	echo -ne $green$1$clear
}


function ShowApacheInfo(){

/usr/local/apache/bin/httpd -v | grep Apache/ | awk '{ print $3}'
}

function ShowInfo() {

ea_version=$(/usr/local/cpanel/bin/rebuild_phpconf --current | grep ea | head -1 | awk '{ print $1}')
if [ -z $ea_version ]; then
        echo "You are runnning EasyApache 3"
else
    	echo "You are running EasyApache 4"
fi

        echo -e "$(ColorGreen "Your Apache version is: "$(ShowApacheInfo)" ")";

        echo -e "$(ColorGreen $(cat /etc/centos-release) )";
}
ShowInfo


