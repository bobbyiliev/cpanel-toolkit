#!/bin/bash
#
# Date: July 30th 2017
# Author: Alex G - SysOps Team at Paragon Internet Group - GoDaddy EMEA
# Email <alex@paragon.net.uk>
#__revision='1.0 (30-July-2017)'
# Script to locate spammers on cPanel servers  (exim)
# The script is created only for internal use on our servers
#############################################################

# Define colors

white='\e[97m'
red='\e[31m'
blue='\e[34m'
orange='\e[33m'
clear='\e[0m'

ColorWhite(){
        echo -ne $white$1$clear
}
ColorRed(){
        echo -ne $red$1$clear
}

ColorBlue(){
        echo -ne $blue$1$clear
}

ColorOrange(){
        echo -ne $orange$1$clear
}


##############################################################
# Start Functions here

function showexim(){
	exigrep @ /var/log/exim_mainlog | grep _login | sed -n 's/.*_login:\(.*\)S=.*/\1/p' | sort -n | uniq -c | sort -n
Menu
}


function originate(){
	grep "cwd=/home" /var/log/exim_mainlog | awk '{for(i=1;i<=10;i++){print $i}}' | sort | uniq -c | grep cwd | sort -n
Menu
}


function originate2(){
	awk '{ if ($0 ~ "cwd" && $0 ~ "home") {print $3} }' /var/log/exim_mainlog | sort | uniq -c | sort -nk 1
Menu
}


function whichphpscript(){
	grep 'cwd=/home' /var/log/exim_mainlog | awk '{print $3}' | cut -d / -f 3 | sort -bg | uniq -c | sort -bg
Menu
}

function getnetstat(){
        netstat -plan | grep :25 | awk {'print $5'} | cut -d: -f 1 | sort | uniq -c | sort -nk 1
Menu
}


function nobodyspam(){
	ps -C exim -fH ewww | awk '{for(i=1;i<=40;i++){print $i}}' | sort | uniq -c | grep PWD | sort -n
Menu
}


function nobodyspamafter(){
	grep "cwd=" /var/log/exim_mainlog | awk '{for(i=1;i<=10;i++){print $i}}' | sort | uniq -c | grep cwd | sort -n
Menu
}

function showeximsum(){
	exim -bpr | exiqsumm -c | head
Menu
}

##############################################################

Menu(){
echo -ne "
$(ColorRed 'SPAM SCAN') $__revision

Main menu

$(ColorOrange '1)') Receive a sorted list of all the email senders in the exim mail queue.
$(ColorOrange '2)') The following scripts will check the script that will originate spam mails.
$(ColorOrange '2.1)') The following scripts will check the script that will originate spam mails. 
$(ColorOrange '3)') See which script is being used to send the spam emails. If it is from php then use.
$(ColorOrange '4)') It shows the IPs which are connected to server through port number 25.
$(ColorOrange '5)') In order to find nobody spamming, issue the following command.
$(ColorOrange '5.1)') The above is valid only if the spamming is currently in progress. If the spamming has happened some hours before, use this one.
$(ColorOrange '6)') The following script will give the summary of mails in the mail queue.


$(ColorRed 'Select an option:') "
                read a
                case $a in
                1) showexim ;;
                2) originate;;
                2.1) originate2;;
                3) whichphpscript;;
                4) getnetstat;;
                5) nobodyspam;;
                5.1) nobodyspamafter;;
                6) showeximsum;;
        esac
}
clear
Menu
