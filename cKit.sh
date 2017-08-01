#!/bin/bash

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
# Function that lists access logs for every website separately
# including POST/GET requests and IP logs. 
##
function access_and_ip_logs() {
for i in $(cat '/etc/userdomains' | grep -v '*' | awk -F":" '{print $1}'); do
                domains=${i};
                username="$(grep ${domains} /etc/userdomains | awk -F": " '{print $2 }' | tail -1)";
                echo "$domains access logs" #>> GETPOST.txt
                cat /home/$username/access-logs/$domains* | awk '{print $6 " " $7}' | sort | uniq -c | sort -rn | head #2>/dev/null 
                echo "$domains IP" #>> GETPOST.txt
                cat /home/$username/access-logs/$domains* | awk '{print $1}' | sort | uniq -c | sort -rn | head #2>/dev/null
        done
MenuAcess
}

##
# Function that lists access logs for every website separately
# including only POST/GET requests. 
##
function OnlyAccessLogs {
for i in $(cat '/etc/userdomains' | grep -v '*' | awk -F":" '{print $1}'); do
                domains=${i};
                username="$(grep ${domains} /etc/userdomains | awk -F": " '{print $2 }' | tail -1)";
                echo "$domains access logs" 
                cat /home/$username/access-logs/$domains* | awk '{print $6 " " $7}' | sort | uniq -c | sort -rn | head #2>/dev/null
        done
}

##
# Function that lists access logs for a specific website 
# including only POST/GET requests. 
##

function SpecificDomainAccessLogs {
for i in $(grep $responsedomain '/etc/userdomains' | grep -v '*' | awk -F":" '{print $1}'); do
                domains=${i};
                username="$(grep ${domains} /etc/userdomains | awk -F": " '{print $2 }' | tail -1)";
                echo "$domains access logs"
                cat /home/$username/access-logs/$domains* | awk '{print $6 " " $7}' | sort | uniq -c | sort -rn | head #2>/dev/null
        done
}

##
# Function that lists all the email senders in the exim mail queue
# You can use it in order to see which emails accounts have authenticated
##
function showexim(){
        exigrep @ /var/log/exim_mainlog | grep _login | sed -n 's/.*_login:\(.*\)S=.*/\1/p' | sort -n | uniq -c | sort -n
EmailsMenu
}

##
# Function that lists the directories from which are sent spam emails
# You can use it in order to see if a directory is being compromised, e.g scan the directories from the result
##
function originate(){
        grep "cwd=/home" /var/log/exim_mainlog | awk '{for(i=1;i<=10;i++){print $i}}' | sort | uniq -c | grep cwd | sort -n
EmailsMenu
}

##
# Function that lists the exact PHP scripts which were sending emails
# You can use it to locate malware PHP mail scripts
##
function originate2(){
	egrep -R "X-PHP-Script"  /var/spool/exim/input/*
EmailsMenu
}

##
# Function that lists the directories from which are sent spam emails
# You can use it in order to see if a directory is being compromised, e.g scan the directories from the result
##
function whichphpscript(){
        grep 'cwd=/home' /var/log/exim_mainlog | awk '{print $3}' | cut -d / -f 3 | sort -bg | uniq -c | sort -bg
EmailsMenu
}

##
# Function that lists all the IPs which are connected on port 25
# You can use it in order to see which IPs were using the insecure port to send emails
##
function getnetstat(){
        netstat -plan | grep :25 | awk {'print $5'} | cut -d: -f 1 | sort | uniq -c | sort -nk 1
EmailsMenu
}

##
# Function that shows if anyone was using the nobody spamming method
# This is very rare case but you can still check for such SPAM messages
##
function nobodyspam(){
       	ps -C exim -fH ewww | awk '{for(i=1;i<=40;i++){print $i}}' | sort | uniq -c | grep PWD | sort -n
EmailsMenu
}

##
# Function that shows if anyone was using the nobody spamming method but shows all the historical emails
# This is very rare case but you can still check for such SPAM messages
##
function nobodyspamafter(){
       	grep "cwd=" /var/log/exim_mainlog | awk '{for(i=1;i<=10;i++){print $i}}' | sort | uniq -c | grep cwd | sort -n
EmailsMenu
}

##
# Function that will give the summary of mails in the mail queue.
# You can use it to see all the emails in the exim mail queue summarized.
##
function showeximsum(){
        exim -bpr | exiqsumm -c | head
EmailsMenu
}

##
# Function that lists all of the sleeping MySQL processes
# In many cases the sleeping processes could be causing high CPU load
##
function list_sleeping_mysql() {
    sleepingProc=$(mysqladmin proc | grep Sleep)
    if [ -z "$sleepingProc" ]; then
        echo "No Sleeping MySQL Proccesses ATM";
    else {
        mysqladmin proc | head -3
        mysqladmin proc | grep Sleep
    }
    fi
MySQLMenu
}

##
# Function that kills all of the sleeping MySQL processes
# In case you need to reduce the CPU load or free up some RAM you could use this function
##
function kill_mysql_sleeping_proc() {
    sleepingProc=$(mysqladmin proc | grep Sleep)
    allowedsleep=60
        if [ -z "$sleepingProc" ]; then
        echo "No Sleeping MySQL Proccesses ATM";
        else
            	for i in $(mysql -e 'show processlist' | grep 'Sleep' | awk '{print $1}'); do
                        #declare -i prockilled=0
                        sleeptime=$(mysqladmin proc | grep "\<$i\>" | grep -v '\-\-' | grep -v 'Time' | awk -F'|' '{ print $7 }' | sed 's/ //g' | tail -1);
                        sleeptime=$((sleeptime + 1))
                        #echo "${i} has been sleeping for ${sleeptime} seconds"
                        if [ "$sleeptime" -gt "$allowedsleep" ]; then
                                echo "Killed proccess: ${i} as it has been sleeping for more than ${allowedsleep} seconds"; mysql -e "kill ${i}";
                                #echo "$i has been sleeping for $sleeptime seconds"
                                prockilled=$((prockilled+1));
                        fi
                done
                if [ ! -z $prockilled ] && [ $prockilled -lt 1 ]; then
                        echo "No quries have been running for more than $allowedsleep seconds"
                elif [ ! -z $prockilled ] && [ $prockilled -eq 1 ]; then
                        echo "Killed only 1 MySQL query that was sleeping for more than $allowedsleep seconds"
                elif [ ! -z $prockilled ] && [ $prockilled -gt 1 ]; then
                        echo "Killed $prockilled MySQL query that was sleeping for more than $allowedsleep seconds"
                else {
                      	echo "No quries have been sleeping for more than $allowedsleep seconds"
                }
                fi
        fi
MySQLMenu
}

##
# Function that kills all of the sleeping MySQL processes
# In case you need to reduce the CPU load or free up some RAM you could use this function
##
function kill_mysql_sleeping_proc_user() {
    echo "Use this if you would like to kill all sleeping MySQL proccesses for 1 MySQL user only"
    unset sqluser	
    while [ -z $sqluser ]; do
    echo "Please Enter MySQL user or type exit:"
    read sqluser
    done
    if [ $sqluser = "exit" ]; then
    MySQLMenu
    #exit 0;
    else
    sleepingProc=$(mysqladmin proc | grep Sleep | grep $sqluser)
    allowedsleep=10
        if [ -z "$sleepingProc" ]; then
        echo "No Sleeping MySQL Proccesses ATM";
        else
            	for i in $(mysql -e 'show processlist' | grep 'Sleep' | awk '{print $1}'); do
                        #declare -i prockilled=0
                        sleeptime=$(mysqladmin proc | grep "\<$i\>" | grep -v '\-\-' | grep -v 'Time' | awk -F'|' '{ print $7 }' | sed 's/ //g' | tail -1);
                        sleeptime=$((sleeptime + 1))
                        #echo "${i} has been sleeping for ${sleeptime} seconds"
                        if [ "$sleeptime" -gt "$allowedsleep" ]; then
                                echo "$sqluser : killed proccess ${i} as it has been sleeping for more than ${allowedsleep} seconds"; mysql -e "kill ${i}";
                                #echo "$i has been sleeping for $sleeptime seconds"
                                prockilled=$((prockilled+1));
                        fi
                done
                if [ ! -z $prockilled ] && [ $prockilled -lt 1 ]; then
                        echo "No quries associated with $sqluser have been running for more than $allowedsleep seconds"
                elif [ ! -z $prockilled ] && [ $prockilled -eq 1 ]; then
                        echo "User: $sqluser .. killed only 1 MySQL query that was sleeping for more than $allowedsleep seconds"
                elif [ ! -z $prockilled ] && [ $prockilled -gt 1 ]; then
                        echo "User: $sqluser .. killed $prockilled MySQL query that was sleeping for more than $allowedsleep seconds"
                else {
                      	echo "User: $sqluser .. No quries have been sleeping for more than $allowedsleep seconds"
                }
                fi
        fi
   fi
MySQLMenu
}

##
# Function that lists all MySQL proccesses
##
function show_full_processlist() {
    mysqladmin processlist status
MySQLMenu
}
##
# Function that shows the MySQL status and uptime
##
function mysql_status(){
    mysqladmin status | grep -v "show processlist"
MySQLMenu
}

##
# Function that shows if an extension is enabled 
##
function is_extension(){
wget -O IsExtension.php https://raw.githubusercontent.com/bobbyiliev/cpanel-toolkit/master/dev/IsExtension.txt

echo "Enter extension:"
read a
if [ -f "IsExtension.php" ]; then
        sed -i "s/extensionExists/$a/g" IsExtension.php
fi
php IsExtension.php
rm IsExtension.php
ToolsMenu
}

##
# Function that shows if a function is enabled
##
function is_function(){
wget -O IsFunction.php https://raw.githubusercontent.com/bobbyiliev/cpanel-toolkit/master/dev/IsFunction.txt


echo "Enter function:"
read a
if [ -f "IsFunction.php" ]; then
        sed -i "s/functionExists/$a/g" IsFunction.php
fi
php IsFunction.php
rm IsFunction.php
ToolsMenu
}

##
# Function that is used as a failsafe of giving
# non-existent commands
##
WrongCommand(){
        echo "Press Enter to go back to Main menu"
        read a
        clear
        MainMenu
}

##
# Function to exit the Main menu
# Use it to exit the script
##

Exitmenu(){
        echo -e $green"Goodbye!"$clear;
        exit 1
}

###########################
###  Quick Access Menu ###
###########################

##
# Access Logs Menu
##
MenuAcess(){

            	ColorGreen "        "
echo -ne "
Choose the information you need regardin Access Logs

$(ColorGreen '1)') GET/POST Requests + IP addresses for every website on the VPS
$(ColorGreen '2)') GET/POST Requests for every website on the VPS
$(ColorGreen '3)') GET/POST Requests for a specific website
$(ColorGreen '0)') Back to Main Menu

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
                1) access_and_ip_logs;;
                2) OnlyAccessLogs;;
		3) MenuAcessDomain;;
		0) MainMenu;;
		*) echo -e $red"Wrong command."$clear; MenuAcess;;
        esac
}

##
#  Section in the Access Logs Menu that ask for a specific domain 
##
MenuAcessDomain(){

	echo -ne "
Please type the domain (example.com)"
                read responsedomain
		SpecificDomainAccessLogs
}

##
# Email Features Menu
##
EmailsMenu(){

            	ColorGreen "        "
echo -ne "
Choose the information you need regarding Email Logs

$(ColorGreen '1)') Receive a sorted list of all the email senders in the exim mail queue.
$(ColorGreen '2)') The following option will display the directories from which the emails are being sent.
$(ColorGreen '3)') The following option will check for emails sent via php script.
$(ColorGreen '4)') The following option will display the users which were sending out emails within their directories.
$(ColorGreen '5)') It shows the IPs which were sending emails via port 25..
$(ColorGreen '6)') In order to find “nobody” spamming, use this option..
$(ColorGreen '7)') The above command is valid only if the spamming is currently in progress If not use this otpion..
$(ColorGreen '8)') The following script will give the summary of mails in the mail queue.
$(ColorGreen '0)') Back to Main Menu.

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
                1) showexim ;;
                2) originate;;
                3) originate2;;
                4) whichphpscript;;
                5) getnetstat;;
                6) nobodyspam;;
                7) nobodyspamafter;;
                8) showeximsum;;
                0) MainMenu;;
		*) echo -e $red"Wrong command."$clear; EmailsMenu;;
        esac
}

##
# The MySQL Menu
##
MySQLMenu(){
                ColorGreen "        "
echo -ne "

Choose the information you need regarding MySQL

$(ColorGreen '1)') List MySQL sleeping Processes.
$(ColorGreen '2)') Kill all MySQL sleeping Processes.
$(ColorGreen '3)') Show full processlist.
$(ColorGreen '4)') Show MySQL status and Uptime.
$(ColorGreen '5)') Kill all MySQL sleeping Processes "for" a specific user.
$(ColorGreen '0)') Back To Main Menu.

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
                1) list_sleeping_mysql;;
                2) kill_mysql_sleeping_proc;;
                3) show_full_processlist;;
 	        4) mysql_status;;
		5) kill_mysql_sleeping_proc_user;;
                0) MainMenu;;
		*) echo -e $red"Wrong command."$clear; MySQLMenu;;
        esac
}

ToolsMenu(){
                ColorGreen "        "
echo -ne "

Cool Tools

$(ColorGreen '1)') Check if an extension is enabled on the server.
$(ColorGreen '2)') Check if a function is enabled on the server.
$(ColorGreen '0)') Back To Main Menu.

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
                1) is_extension;;
                2) is_function;;
                0) MainMenu;;
		*) echo -e $red"Wrong command."$clear; ToolsMenu;;
        esac
}

#################
# The Main Menu #
#################
MainMenu(){
clear
                ColorGreen "        "
echo -ne "
Main Menu
$(ColorGreen '1)') Access Logs Menu
$(ColorGreen '2)') SPAM Scan Menu
$(ColorGreen '3)') MySQL Menu
$(ColorGreen '4)') Handy Tools
$(ColorGreen '0)') Exit

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
                1) MenuAcess;;
		2) EmailsMenu;;
		3) MySQLMenu;;
		4) ToolsMenu;;
		0) Exitmenu;;
		*) echo -e $red"Wrong command."$clear; WrongCommand;;
        esac
}
clear
MainMenu
