#!/bin/bash
# DDos and traffic script
###################
###  Variables  ###
###################
green='\e[32m'
blue='\e[34m'
clear='\e[0m'
red='\e[31m'

###################
###  Functions  ###
###################

ColorGreen(){
	echo -ne $green$1$clear
}
ColorBlue(){
	echo -ne $blue$1$clear
}

##
# Function that lists the Ips which are connected to server and how many connections exist from each IP
# You can easy it in case of severe traffic going to the server
##
function ActiveConn(){
	netstat -anp |grep 'tcp\|udp' | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -n
DDoSMenu
}

##
# Function that lists the users which are running the most processes at the moment - the top 5 users
# You can use it in order to determinate which user is giving the spike on the server's load
##
function TopUsers(){
	ps aux | awk '{print $1}' | sort | uniq -c | sort -nk1 | tail -n5
DDoSMenu
}

##
# Function that lists the total process running by the users
# You can use to see all users which are running processes at the moment
##
function AllUsers(){
	ps aux | awk '{print $1}' | sort | uniq -c | sort -nk1
DDoSMenu
}

##
# Function that shows the % CPU usage at the moment
# You can use it in order to determinate if the current traffic is causingg too much CPU usage
##
function CurrentCPUusage(){
	grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage "%"}'
DDoSMenu
}

##
# Function that lists all the active connections for a specific port defined by the script user
# You can use the option to see the traffic for every port you need
##
function GetPortConn(){
	unset specport
	while [ -z $specport ]; do
        echo "Please enter the desired port:"
	read specport
        done
        if [ $specport = "exit" ]; then
	DDoSMenu
	else
        netstat -plan | grep :$specport | awk {'print $5'} | cut -d: -f 1 | sort | uniq -c | sort -nk 1
	fi
       	DDoSMenu
}


function Exitmenu(){
	echo -e $green"Goodbye!"$clear;
        exit 1
}
######################################### Main Menu ######################################################

DDoSMenu(){
                ColorGreen "        "
echo -ne "
Main Menu
$(ColorGreen '1)') Lists the Ips which are connected to server and how many connections exist from each IP
$(ColorGreen '2)') lists the users which are running the most processes at the moment - the top 5 users
$(ColorGreen '3)') Function that lists the total process running by the users
$(ColorGreen '4)') Function that shows the % CPU usage at the moment
$(ColorGreen '5)') Function that lists all the active connections for a specific port defined by the script user
$(ColorGreen '0)') Exit

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
		1) ActiveConn;;
                2) TopUsers;;
                3) AllUsers;;
                4) CurrentCPUusage;;
                5) GetPortConn;;
                0) Exitmenu;;
                *) echo -e $red"Wrong command."$clear; WrongCommand;;
        esac
}
clear
DDoSMenu
