#!/bin/bash
###################
###  Variables  ###
###################
green='\e[32m'
blue='\e[34m'
clear='\e[0m'
red='\e[31m'
executionTime=`date +%Y-%m-%d:%H:%M:%S`
server=$(hostname)
location=$(pwd)
#reportDomain='http://wpcli.bobbyiliev.com/ckit/datalog/datalog.php'
reportDomain='http://ckit.bobbyiliev.com/datalog.php'

##################################################################
### If you would like to disable logging just change this to 0 ###
##################################################################
enablelog=1
###################
###  Functions  ###
###################
ColorGreen(){
	echo -ne $green$1$clear
}
ColorBlue(){
	echo -ne $blue$1$clear
}
ColorRed(){
	echo -ne $red$1$clear
}

function welcome() {
	echo $(ColorGreen '### Some Useful Information ###' )

	echo "The server is using about $(ColorGreen "$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage "%"}')" ) of its CPU  Power"

	echo "Total of $(ColorGreen "$(free -mh | grep Mem | awk '{ print $2 }') ") RAM installed"

	echo "Total of $(ColorGreen "$(lscpu | grep -v 'node' | grep 'CPU(s):' | awk '{ print $2 }')") CPU(s)"

	echo "OS: $(cat /etc/redhat-release)"

	echo "If CentOS is under version 6, EasyApache 4 and Let's Encrypt can NOT be installed"
}

welcome
