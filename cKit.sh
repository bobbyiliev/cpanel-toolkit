#!/bin/bash

## STILL IN DEVELOPMENT !!! ###

######################################################################
# Date: July 25th 2017                                               #
# Authors:                                                           #
#  - Bobby I. - MSD Team at Paragon Internet Group - GoDaddy EMEA    #
#  - Alex G - SysOps Team at Paragon Internet Group - GoDaddy EMEA   #
#  - Kalin D. - SysOps Team at Paragon Internet Group - GoDaddy EMEA #
# Emails:                                                            #
# <bobby@paragon.net.uk>                                             #
# <alex@paragon.net.uk>                                              #
# <kalin.dimitrov@paragon.net.uk>                                    #
# __revision='1.0'                                                   #
# Simple cPanel Terminal ToolKit that would help you manage and      #
# troubleshoot issues with your server easily via SSH                #
######################################################################

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
deletescript(){
        if [ -f "$0" ]; then rm -f "$0"; fi
        echo; exit 0
}

trap deletescript INT 20 EXIT

ColorGreen(){
	echo -ne $green$1$clear
}
ColorBlue(){
	echo -ne $blue$1$clear
}
ColorRed(){
	echo -ne $red$1$clear
}

##
# Function that lists access logs for every website separately
# including POST/GET requests and IP logs. 
##
function access_and_ip_logs() {
for i in $(cat '/etc/userdomains' | grep -v '*' | awk -F":" '{print $1}'); do
                domains=${i};
                username="$(grep ${domains} /etc/userdomains | awk -F": " '{print $2 }' | tail -1)";
		echo  $(ColorGreen "#####################");
                echo $(ColorGreen "GET/POST requests for $domains :");
		grep -r $domains /usr/local/apache/domlogs/* 2>/dev/null | awk '{print $6 " " $7}' | sort | uniq -c | sort -rn | head
                echo $(ColorGreen "IP hits for $domains :");
                #cat /home/$username/access-logs/$domains* 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -rn | head
		#grep $domains /home/$username/access-logs/* 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -rn | head
		grep -r $domains /usr/local/apache/domlogs/* 2>/dev/null | awk -F":" '{print $2}' | awk -F"-" '{print $1}' |sort | uniq -c | sort -rn | head
		echo $(ColorGreen "#####################");
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
        	echo  $(ColorGreen "#####################");
	        echo  $(ColorGreen "GET/POST requests for $domains :");
                #cat /home/$username/access-logs/$domains* 2>/dev/null | awk '{print $6 " " $7}' | sort | uniq -c | sort -rn | head 
		grep -r $domains /usr/local/apache/domlogs/* 2>/dev/null | awk '{print $6 " " $7}' | sort | uniq -c | sort -rn | head
		echo  $(ColorGreen "#####################");
        done
MenuAcess
}

##
# Function that lists access logs for a specific website 
# including only POST/GET requests. 
##

function SpecificDomainAccessLogs {
for i in $(grep $responsedomain '/etc/userdomains' | grep -v '*' | awk -F":" '{print $1}'); do
                domains=${i};
		if [ -z $domains ] ; then
			echo "Domain not found on this server! Please check for typos or try another domain."
		MenuAcessDomain
		else {
	                username="$(grep ${domains} /etc/userdomains | awk -F": " '{print $2 }' | tail -1)";
        	        echo  $(ColorGreen "GET/POST requests for $domains :");
                	#cat /home/$username/access-logs/$domains* 2>/dev/null | awk '{print $6 " " $7}' | sort | uniq -c | sort -rn | head
			grep -r $domains /usr/local/apache/domlogs/* 2>/dev/null | awk '{print $6 " " $7}' | sort | uniq -c | sort -rn | head
        	        echo  $(ColorGreen "IP hits for $domains :");
	                grep -r $domains /usr/local/apache/domlogs/* 2>/dev/null | awk -F":" '{print $2}' | awk -F"-" '{print $1}' |sort | uniq -c | sort -rn | head
                	echo  $(ColorGreen  "#####################");
		}
		fi
        done
}

##
# Function that lists access logs for IP on a specific website 
##

function SpecificDomainAccessLogsWithIP {
for i in $(grep $responsedomain '/etc/userdomains' | grep -v '*' | awk -F":" '{print $1}'); do
                domains=${i};
                if [ -z $domains ] ; then
                        echo  $(ColorGreen "Domain not found on this server! Please check for typos or try another domain.");
                MenuAcessDomain
                else {
                        username="$(grep ${domains} /etc/userdomains | awk -F": " '{print $2 }' | tail -1)";
                        echo  $(ColorGreen "$domains access logs");
			grep -r $domains /usr/local/apache/domlogs/* 2>/dev/null | grep $responseIP | awk '{print $6 " " $7}' | sort | uniq -c | sort -rn | head
                        echo  $(ColorGreen "#####################");
                }
                fi
        done
}

##
# Function that lists all the email senders in the exim mail queue
# You can use it in order to see which emails accounts have authenticated
##
function showexim(){
	count=$(exigrep @ /var/log/exim_mainlog | grep _login | sed -n 's/.*_login:\(.*\)S=.*/\1/p' | sort -n | uniq -c | sort -n | wc -l)
	if [ $count -ne 0 ]; then
		exigrep @ /var/log/exim_mainlog | grep _login | sed -n 's/.*_login:\(.*\)S=.*/\1/p' | sort -n | uniq -c | sort -n
	else
            	echo "No results found! Try another option."
        fi
EmailsMenu
}

##
# Function that lists the directories from which are sent spam emails
# You can use it in order to see if a directory is being compromised, e.g scan the directories from the result
##
function originate(){
        count=$(grep "cwd=/home" /var/log/exim_mainlog | awk '{for(i=1;i<=10;i++){print $i}}' | sort | uniq -c | grep cwd | sort -n | wc -l)
        if [ $count -ne 0 ]; then
                grep "cwd=/home" /var/log/exim_mainlog | awk '{for(i=1;i<=10;i++){print $i}}' | sort | uniq -c | grep cwd | sort -n
        else
            	echo "No results found! Try another option."
        fi
EmailsMenu
}

##
# Function that lists the exact PHP scripts which were sending emails
# You can use it to locate malware PHP mail scripts
##
function originate2(){
	count=$(egrep -R "X-PHP-Script"  /var/spool/exim/input/* | wc -l)
	if [ $count -ne 0 ]; then
		egrep -R "X-PHP-Script"  /var/spool/exim/input/*
	else
                echo "No results found! Try another option."
        fi
EmailsMenu
}

##
# Function that lists the directories from which are sent spam emails
# You can use it in order to see if a directory is being compromised, e.g scan the directories from the result
##
function whichphpscript(){
        count=$(grep 'cwd=/home' /var/log/exim_mainlog | awk '{print $3}' | cut -d / -f 3 | sort -bg | uniq -c | sort -bg | wc -l)
	if [ $count -ne 0 ]; then
		grep 'cwd=/home' /var/log/exim_mainlog | awk '{print $3}' | cut -d / -f 3 | sort -bg | uniq -c | sort -bg
	else
                echo "No results found! Try another option."
        fi
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
	count=$(grep "cwd=" /var/log/exim_mainlog | awk '{for(i=1;i<=10;i++){print $i}}' | sort | uniq -c | grep cwd | sort -n | wc -l)
	if [ $count -ne 0 ]; then
		grep "cwd=" /var/log/exim_mainlog | awk '{for(i=1;i<=10;i++){print $i}}' | sort | uniq -c | grep cwd | sort -n
	else
                echo "No results found! Try another option."
        fi
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
# Startup MySQL Info
##
function check_mysql_startup_info() {
	#Get MySQL connections value
	allowed=$(mysql -e 'show variables like "max_connections"' | grep 'max_conn' | awk '{print $2}')
	current=$(mysqladmin proc | grep -v Id | grep -v '\-\-\-' | wc | awk '{ print $1}')
	percent=$(awk "BEGIN { pc=100*${current}/${allowed}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
	alright=65;
	echo ""
	echo "You are using $(ColorGreen $current) of the allowed $(ColorGreen $allowed) MySQL connections"
	if [ "$percent" -lt "$alright" ]; then
		echo "It is OK, you are using only $(ColorGreen ${percent})% of the allowed MySQL connections";
	elif [[ ${percent} -gt 65 ]] && [[ ${percent} -lt 85 ]] ; then
		echo "Be careful! You are using $(ColorBlue ${percent})% of the allowed MySQL connections";
	elif [[ $percent -gt 90 ]]; then
		echo "Attention! Check with your friendly SysOps! The server is using more than $(ColorRed ${percent})% of the allowed MySQL connections";
	fi
}


##
# Function that lists all of the sleeping MySQL processes
# In many cases the sleeping processes could be causing high CPU load
##
function list_sleeping_mysql() {
    sleepingProc=$(mysqladmin proc | grep Sleep)
    if [ -z "$sleepingProc" ]; then
	echo ""
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
trap command SIGINT
    sleepingProc=$(mysqladmin proc | grep Sleep)
    allowedsleep=60
    unset password
    while [ -z $password ] ; do
    echo "Only for SysAdmins! Please enter the secret password or type exit:"
    read password
    done
    if [ $password = "SysAdmins" ]; then
    unset password
        if [ -z "$sleepingProc" ]; then
	echo ""
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
	fi
trap - SIGINT
SysAdminsMenu
}

##
# Function that kills all of the sleeping MySQL processes
# In case you need to reduce the CPU load or free up some RAM you could use this function
##
function kill_mysql_sleeping_proc_user() {
    trap command SIGINT
    echo ""
    echo "Use this if you would like to kill all sleeping MySQL proccesses for 1 MySQL user only"
    unset password
    echo ""
    while [ -z $password ] ; do
        echo "Only for SysAdmins! Please enter the secret password or type exit:"
    read password
    done
    if [ $password = "SysAdmins" ]; then
    unset password
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
  fi
trap - SIGINT
SysAdminsMenu
}

##
# Function that lists all of the sleeping MySQL processes for the Admins Menu
# In many cases the sleeping processes could be causing high CPU load
##
function list_sleeping_mysql_admins() {
    sleepingProc=$(mysqladmin proc | grep Sleep)
    if [ -z "$sleepingProc" ]; then
        echo ""
        echo "No Sleeping MySQL Proccesses ATM";
    else {
       	mysqladmin proc | head -3
       	mysqladmin proc | grep Sleep
    }
    fi
SysAdminsMenu
}

##
# Function that lists all MySQL proccesses for Admins Menu
##
function show_full_processlist_admins() {
    check_mysql_startup_info
    mysqladmin processlist status
SysAdminsMenu
}


##
# Function that lists all MySQL proccesses
##
function show_full_processlist() {
    check_mysql_startup_info
    mysqladmin processlist status
MySQLMenu
}
##
# Function that shows the MySQL status and uptime
##
function mysql_status(){
    check_mysql_startup_info
    mysqladmin status | grep -v "show processlist"
MySQLMenu
}

##
# Function that shows if an extension is enabled 
##
function is_extension(){
trap command SIGINT
wget --no-check-certificate -Nq -O IsExtension.php https://raw.githubusercontent.com/bobbyiliev/cpanel-toolkit/master/dev/IsExtension.txt

echo "Enter extension:"
read a
if [ -f "IsExtension.php" ]; then
        sed -i "s/extensionExists/$a/g" IsExtension.php
fi
php IsExtension.php
rm IsExtension.php
trap - SIGINT
ToolsMenu
}

##
# Function that shows if an extension is enabled  on the Cloud
##
function is_extensionCloud(){
trap command SIGINT
wget --no-check-certificate -Nq -O IsExtension.php https://raw.githubusercontent.com/bobbyiliev/cpanel-toolkit/master/dev/IsExtension.txt

echo "Enter extension:"
read a
if [ -f "IsExtension.php" ]; then
        sed -i "s/extensionExists/$a/g" IsExtension.php
fi
php IsExtension.php
rm IsExtension.php
trap - SIGINT
CloudMenu
}


##
# Function that shows if a function is enabled
##
function is_function(){
trap command SIGINT
wget --no-check-certificate -O IsFunction.php https://raw.githubusercontent.com/bobbyiliev/cpanel-toolkit/master/dev/IsFunction.txt


echo "Enter function:"
read a
if [ -f "IsFunction.php" ]; then
        sed -i "s/functionExists/$a/g" IsFunction.php
fi
php IsFunction.php
rm IsFunction.php
trap - SIGINT
ToolsMenu
}

##
# Function that shows if a function is enabled on the Cloud
##
function is_functionCloud(){
trap command SIGINT
wget --no-check-certificate -O IsFunction.php https://raw.githubusercontent.com/bobbyiliev/cpanel-toolkit/master/dev/IsFunction.txt


echo "Enter function:"
read a
if [ -f "IsFunction.php" ]; then
        sed -i "s/functionExists/$a/g" IsFunction.php
fi
php IsFunction.php
rm IsFunction.php
trap - SIGINT
CloudMenu
}

##
# Function that is used as a failsafe of giving
# non-existent commands
##
WrongCommand(){
        echo "Press Enter to go back to Main menu"
        read a
        tput clear
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

##
# Funtcion contributed by Zack
# Works on cPanel servers - Shows the top 5 users the most CPU + RAM + MySQL
##

function Zack(){
OUT=$(/usr/local/cpanel/bin/dcpumonview | grep -v Top | sed -e 's#<[^>]*># #g' | while read i ; do NF=`echo $i | awk {'print NF'}` ; if [[ "$NF" == "5" ]] ; then USER=`echo $i | awk {'print $1'}`; OWNER=`grep -e "^OWNER=" /var/cpanel/users/$USER | cut -d= -f2` ; echo "$OWNER $i"; fi ; done) ; (echo "USER CPU" ; echo "$OUT" | sort -nrk4 | awk '{printf "%s %s%\n",$2,$4}' | head -5) | column -t ;echo;(echo -e "USER MEMORY" ; echo "$OUT" | sort -nrk5 | awk '{printf "%s %s%\n",$2,$5}' | head -5) | column -t ;echo;(echo -e "USER MYSQL" ; echo "$OUT" | sort -nrk6 | awk '{printf "%s %s%\n",$2,$6}' | head -5) | column -t ;
DDoSMenu
}

##
# Function that monitors the CPU usage
##
function MonitorCpu(){
trap command SIGINT
while true; do 
        echo '';
        echo 'The current CPU usage is:'; 
        grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage "%"}' || break
        echo '';
        echo $(ColorGreen "To stop the script press 'Ctrl+C'")
        sleep 2 || break
done
	trap - SIGINT
	ToolsMenu
}

##
# Function that generates a random password
# You can use it whenever you need to enter new password
##
function randompass(){
        cat /dev/urandom | tr -dc 'a-zA-Z0-9-!@#$%^&*()+{}|:<>?=' | fold -w 12 | head -1
        echo "Do you want to generate longer password[yes/no]"
        read answer
        if [ ! -z $answer ] && [ $answer = "yes" ]; then
        cat /dev/urandom | tr -dc 'a-zA-Z0-9-!@#$%^&*()+{}|:<>?=' | fold -w 20 | head -1
else {
        echo "Exit then"
}
fi
ToolsMenu
}

##
# Function that generates a random password on the Cloud
# You can use it whenever you need to enter new password
##
function randompass_cloud(){
        cat /dev/urandom | tr -dc 'a-zA-Z0-9-!@#$%^&*()+{}|:<>?=' | fold -w 12 | head -1
        echo "Do you want to generate longer password[yes/no]"
        read answer
        if [ ! -z $answer ] && [ $answer = "yes" ]; then
        cat /dev/urandom | tr -dc 'a-zA-Z0-9-!@#$%^&*()+{}|:<>?=' | fold -w 20 | head -1
else {
       	echo "Exit then"
}
fi
CloudMenu
}

##
# Function that finds files larger than 100MB in /home/
##
function FindLargeFiles(){
trap command SIGINT
 	echo $(ColorGreen "This might take some time. To stop the script press 'Ctrl+C'")
	ionice -n 3 -c 3 find /home ! -path "/home/virtfs/*" -type f -size +100M -exec du -hs {} \;
	trap - SIGINT
ToolsMenu
}

###
# Function that shows the current EA version
###
function EAversion(){

ea_version=$(/usr/local/cpanel/bin/rebuild_phpconf --current | grep ea | head -1 | awk '{ print $1}')
if [ -z $ea_version ]; then
        echo "You are runnning EasyApache 3"
else
        echo "You are running EasyApache 4"
fi
ToolsMenu
}
#############################
### Cloud Functoions Only ###
#############################

##
# Function that installs wp-cli on the Cloud platform
##
function wp_cli_cloud_install() {
	echo -e "\e[92mImportant! Use only on the Cloud \e[97m"
	echo -e "\e[92mAre you running this on the cloud? Enter [yes/no] \e[97m" 
	unset answer
	read answer
	while [ -z $answer ]; do
		echo -e "\e[92mAre you running this on the cloud? [yes/no] \e[97m"
	read answer
	done
	if [ $answer = "yes" ]; then

		cd ~/
		curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
		chmod +x wp-cli.phar
		echo '' >> ~/.bashrc
		CLI_ALIAS="alias wp='/usr/bin/php-5.6-cli ~/wp-cli.phar'"
		if grep -q "alias wp='/usr/bin/php-5.6-cli ~/wp-cli.phar'" ".bashrc"
		then
			echo ""
			echo -e "\e[92mwpcli has already been installed, no need of running the command again"	
		else 
			echo $CLI_ALIAS >> ~/.bashrc
		fi

		echo ""
		echo -e "\e[92mTo test the installation, exit the script and then run: "
		echo -e 'source ~/.bashrc'
		echo -e "\e[92mwp plugin list --path='public_html'"
		echo -e "\e[97mAnd that's all!"
	fi
CloudMenu
}

##
# Function that installs composer on the Cloud platform
##
function composer_cloud_install() {
        echo -e "\e[92mImportant! Use only on the Cloud \e[97m"
        echo -e "\e[92mAre you running this on the cloud? Enter [yes/no] \e[97m"
        unset answer
        read answer
        while [ -z $answer ]; do
                echo -e "\e[92mAre you running this on the cloud? [yes/no] \e[97m"
        read answer
        done
	if [ $answer = "yes" ]; then
		cd ~/
		mkdir -p ~/bin/composer
		#ln -s /usr/bin/php-5.6-cli php
		ln -s /usr/bin/php-7.0 php
              	ln -s /usr/bin/php-7.0 ~/bin/php
		curl -sS https://getcomposer.org/installer | /usr/bin/php-5.6-cli
		mv ~/composer.phar ~/bin/composer/ 
		echo '' >> ~/.bashrc
		COMPOSER="alias composer='/usr/bin/php-5.6-cli ~/bin/composer/composer.phar'"
		if grep -q "alias composer='/usr/bin/php-5.6-cli ~/bin/composer/composer.phar'" ".bashrc"
		then
			echo "composer has already been installed, no need of running the command again"
		else
			echo $COMPOSER >>  ~/.bashrc
		fi
	echo -e ""
	echo -e "\e[92mTo test the installation, exit the script and then run: "
	echo -e 'source ~/.bashrc'
	echo -e "\e[92mcomposer --version"
	echo -e "\e[97mAnd that's all!!"
	fi
CloudMenu
}

##
# Function that installs laravel on the Cloud platform
# Laravel Auto Installer - Cloud Platform Only
##
function laravel_cloud_installer() {
        echo -e "\e[92mImportant! Use only on the Cloud \e[97m"
        echo -e "\e[92mAre you running this on the cloud? Enter [yes/no] \e[97m"
        unset answer
        read answer
        while [ -z $answer ]; do
                echo -e "\e[92mAre you running this on the cloud? [yes/no] \e[97m"
        read answer
        done
	if [ $answer = "yes" ]; then
		echo "#  Laravel Auto Installer - Cloud Platform Only  #"

			cd ~/

			###
			# The bellow fixes the issue where some scripts detect a wrong php version due to the new #!/usr/bin/env php shebang
			###

			if grep -q 'HOME/bin' ~/.bashrc 
			then
				echo "You already have a custom bin folder."
			else
			echo "
if [ -d "\$HOME/bin" ] ; then
PATH="\$HOME/bin:\$PATH"
fi" >> ~/.bashrc
			fi

			source ~/.bashrc

			mkdir -p ~/bin/composer

			ln -sfn /usr/bin/php-7.0 php
			ln -sfn /usr/bin/php-7.0 ~/bin/php

			sed -i "s/5.4/5.6/g" ~/.bashrc

			source ~/.bashrc

			###
			# Install Composer
			###

			curl -sS https://getcomposer.org/installer | /usr/bin/php-7.0

			mv ~/composer.phar ~/bin/composer/ 

			echo '' >> ~/.bashrc

			COMPOSER="alias composer='/usr/bin/php-7.0 ~/bin/composer/composer.phar'"

			if grep -q "alias composer='/usr/bin/php-7.0 ~/bin/composer/composer.phar'" ".bashrc"

			then
				echo "No need of running the command again"
			else
				echo $COMPOSER >>  ~/.bashrc
			fi

			###
			# Create the new laravel project:
			###

			/usr/bin/php-7.0 ~/bin/composer/composer.phar create-project --prefer-dist laravel/laravel project

			wait

			###
			# Create a symlink for ~/project/public to public_html so that the laravel installation could be accessed directly via the domain rather than domain.com/public
			###
			if [ -d ~/public_html ]; then
				ln -s ~/project/public ~/public_html/public

				echo ""
        		        echo -e "\e[92mLaravel has been installed at ~/public_html/public"
				domainname=$(pwd | awk -F"/" '{ print $5}')
				echo "Visit $domainname/public to make sure that it is working."
				echo -e "\e[92mIf you are getting a Syntax error, please change the PHP version to PHP 7+"
				echo -e "\e[92mAlso, you can use this .htaccess rule to make the site load from the domain itself $domainname rather than the $domainname/public subfolder\e[97m"
				echo ""
				echo '<IfModule mod_rewrite.c>'
				echo '    RewriteEngine On'
				echo '    RewriteRule ^(.*)$ public/$1 [L]'
				echo '</IfModule>'
				echo ""
				echo -e "\e[92mAny questions, please check with Bobby\e[97m"
			else
				echo -e "\e[92mYou do not have a public_html folder!"
				echo -e "\e[92mLaravel has been installed at ~/project/public"
				echo ""
				echo -e "Additional information: "
                                echo -e "\e[92mIf you are getting a Syntax error, please change the PHP version to PHP 7+"
                                echo -e "\e[92mAlso, you can use this .htaccess rule to make the site load from the domain itself $domainname rather than the $domainname/public subfolder\e[97m"
                               	echo ""
                                echo '<IfModule mod_rewrite.c>'
                                echo '    RewriteEngine On'
                                echo '    RewriteRule ^(.*)$ public/$1 [L]'
                                echo '</IfModule>'
                               	echo ""
                                echo -e "\e[92mAny questions, please check with Bobby\e[97m"
			fi
	fi
CloudMenu
}

##
# Function that changes the Shell PHP vesrion on the Cloud
##
function ChangeShellPHP(){
if [ ! -f ~/.bashrc ]; then
   cd   
   touch ".bashrc" 2>/dev/null
fi
echo -ne "$(ColorGreen '-Checking if export TERM=xterm and export PATH=$PATH need to be added to .bashrc:')";
if grep -q "export TERM=xterm" ".bashrc" 2>/dev/null
then
    echo -ne "
$(ColorGreen '-TERM already exists in .bashrc -skipping')"
else
    echo -e "export TERM=xterm\n$(cat ~/.bashrc 2>/dev/null)" > ~/.bashrc 2>/dev/null
    echo -ne "
$(ColorGreen '-TERM added to .bashrc')"
fi
if [[ ! $(grep "alias php=/usr/bin/php-*" ".bashrc") ]];then
echo -e 'alias php=/usr/bin/php-7.0'  >> ~/.bashrc
else
grep 'alias php=/usr/bin/*'  ~/.bashrc | sed -i "s/php-5\../php-7\.0/"  ~/.bashrc 2>/dev/null
fi
if grep -q 'export PATH=$PATH' ".bashrc"  2>/dev/null
then
    echo -ne "
$(ColorGreen '-PATH already exists in .bashrc-skipping')"
else
    echo -e 'export PATH=$PATH' >> ~/.bashrc
    echo -ne "
$(ColorGreen '-PATH added to .bashrc')"
fi
echo  -ne "
$(ColorGreen '-Version changed to 7. Please run source ~/.bashrc in order to complete the process.')
";
}

##
# Function that detirmines the current executed PHP version and deployes an optimized php.ini
# while configuring the SuPHP_ConfigPath
##
function DeployPHPini(){
	whichletter="$(pwd | awk -F/ '{print $4}')"
	whichdomain="$(pwd | awk -F/ '{print $5}')"

if [ ! -f ~/public_html/.htaccess ]; then
   		cd ~/public_html/  
		touch ".htaccess" #2>/dev/null
		echo -ne "$(ColorGreen '- .htaccess does not exists. Creating the file in public_html/')
";
fi

#If there is no Addtype added in public_html/.htaccess, automatically is asumed the PHP version is 5.6 and adds php.ini for it
if ! grep -qi "AddType x-httpd-ph*" ~/public_html/.htaccess 2>/dev/null
then
		echo "$(ColorGreen 'There is no AddType in the .htaccess. This means the website is using the default PHP version which is 5.6')
                ";
		cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-6
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-6 php.ini 2>/dev/null
		echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
	if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
            	echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
	elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                    	grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
  	else
            	echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

	fi
fi

#Automatically creates an optimized php.ini for PHP 5.6 and configures the suPHP_config path to the .htaccess
if grep -qi "AddType x-httpd-php56 .php" ~/public_html/.htaccess 2>/dev/null
then
		echo "$(ColorGreen 'The current PHP version is 5.6')
		";
		cd ~/public_html/
		mv php.ini php.ini-old 2>/dev/null
		cd
		mv php.ini php.ini-old 2>/dev/null
		wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-6
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been 
created.')
";
		mv php.ini-5-6 php.ini 2>/dev/null
		echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
        elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
        else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

#Automatically creates an optimized php.ini for PHP 5.5 and configures the suPHP_config path to the .htaccess
if grep -qi "AddType x-httpd-php55 .php" ~/public_html/.htaccess 2>/dev/null
then
                echo "$(ColorGreen 'The current PHP version is 5.5')
                ";
                cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
		mv php.ini php.ini-old 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-5
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been 
created.')
";

                mv php.ini-5-5 php.ini
		echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
        elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
        else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

#Automatically creates an optimized php.ini for PHP 5.4 and configures the suPHP_config path to the .htaccess
if grep -qi "AddType x-httpd-php54 .php" ~/public_html/.htaccess 2>/dev/null
then
                echo "$(ColorGreen 'The current PHP version is 5.4')
                ";
                cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
		mv php.ini php.ini-old 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-4
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been 
created.')
";

                mv php.ini-5-4 php.ini
		echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
        elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
        else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

#Automatically creates an optimized php.ini for PHP 7 and configures the suPHP_config path to the .htaccess
if grep -qi "AddType x-httpd-php7 .php" ~/public_html/.htaccess 2>/dev/null
then
                echo "$(ColorGreen 'The current PHP version is 7')
               	";
               	cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
               	cd
		mv php.ini php.ini-old 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-7
		echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been 
created.')
";

                mv php.ini-7 php.ini
		echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
        elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
        else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

#Automatically creates an optimized php.ini for PHP 7.1 and configures the suPHP_config path to the .htaccess
if grep -qi "AddType x-httpd-php71 .php" ~/public_html/.htaccess 2>/dev/null
then
                echo "$(ColorGreen 'The current PHP version is 7.1')
                ";
                cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-7
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been 
created.')
";

                mv php.ini-7 php.ini
		echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
        elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
        else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

#Automatically creates an optimized php.ini for PHP 5.3 and configures the suPHP_config path to the .htaccess
if grep -qi "AddType x-httpd-php53 .php" ~/public_html/.htaccess 2>/dev/null
then
                echo "$(ColorGreen 'The current PHP version is 5.3')
                ";
                cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-3
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been 
created.')
";

                mv php.ini-5-3 php.ini
		echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
        elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
        else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi
ChangePHPVersion
}

##
# Function to change the PHP version to 5.3 and create an optimized PHP.ini file
##
function changePHPTo5.3(){
        whichletter="$(pwd | awk -F/ '{print $4}')"
        whichdomain="$(pwd | awk -F/ '{print $5}')"

if grep -qi "AddType x-httpd-php53 .php" ~/public_html/.htaccess 2>/dev/null
then
    echo -ne "$(ColorGreen '- The current PHP version is 5.3, nothing to do.')
";
fi

if grep -qi "AddType x-httpd-php56 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.6, changing to 5.3.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php56 .php'  ~/public_html/.htaccess | sed -i 's#php56 #php53 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-3
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-3 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php55 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.5, changing to 5.3.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php55 .php'  ~/public_html/.htaccess | sed -i 's#php55 #php53 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-3
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-3 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php7 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 7, changing to 5.3.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php7 .php'  ~/public_html/.htaccess | sed -i 's#php7 #php53 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-3
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-3 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php71 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 7.1, changing to 5.3.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php71 .php'  ~/public_html/.htaccess | sed -i 's#php71 #php53 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-3
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-3 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if ! grep -qi "AddType x-httpd-php*" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.6, changing to 5.3.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                echo -e "AddType x-httpd-php53 .php\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-3
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-3 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi
ChangePHPVersion
}

##
# Function to change the PHP version to 5.4 and create an optimized PHP.ini file
##
function changePHPTo5.4(){
        whichletter="$(pwd | awk -F/ '{print $4}')"
        whichdomain="$(pwd | awk -F/ '{print $5}')"

if grep -qi "AddType x-httpd-php54 .php" ~/public_html/.htaccess 2>/dev/null
then
    echo -ne "$(ColorGreen '- The current PHP version is 5.4, nothing to do.')
";
fi

if grep -qi "AddType x-httpd-php56 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.6, changing to 5.4.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php56 .php'  ~/public_html/.htaccess | sed -i 's#php56 #php54 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-4
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-4 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php53 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.3, changing to 5.4.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php53 .php'  ~/public_html/.htaccess | sed -i 's#php53 #php54 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-4
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-4 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php55 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.5, changing to 5.4.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php55 .php'  ~/public_html/.htaccess | sed -i 's#php55 #php54 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-4
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-4 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php7 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 7, changing to 5.4.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php7 .php'  ~/public_html/.htaccess | sed -i 's#php7 #php54 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-4
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-4 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php71 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 7.1, changing to 5.4.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php71 .php'  ~/public_html/.htaccess | sed -i 's#php71 #php54 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-4
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-4 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if ! grep -qi "AddType x-httpd-php*" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.6, changing to 5.4.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                echo -e "AddType x-httpd-php54 .php\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-4
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-4 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi
ChangePHPVersion
}

##
# Function to change the PHP version to 5.5 and create an optimized PHP.ini file
##
function changePHPTo5.5(){
        whichletter="$(pwd | awk -F/ '{print $4}')"
        whichdomain="$(pwd | awk -F/ '{print $5}')"

if grep -qi "AddType x-httpd-php55 .php" ~/public_html/.htaccess 2>/dev/null
then
    echo -ne "$(ColorGreen '- The current PHP version is 5.5, nothing to do. 
        If you want to have an optimized php.ini, please run the Optimize PHP.ini option')
";
fi

if grep -qi "AddType x-httpd-php53 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.3, changing to 5.5.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php53 .php'  ~/public_html/.htaccess | sed -i 's#php53 #php55 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-5
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-5 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php54 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.4, changing to 5.5.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php54 .php'  ~/public_html/.htaccess | sed -i 's#php54 #php55 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-5
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-5 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php56 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.6, changing to 5.5.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php55 .php'  ~/public_html/.htaccess | sed -i 's#php55 #php55 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-5
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-5 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php7 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 7, changing to 5.5.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php7 .php'  ~/public_html/.htaccess | sed -i 's#php7 #php55 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-5
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-5 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php71 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 7.1, changing to 5.5.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php71 .php'  ~/public_html/.htaccess | sed -i 's#php71 #php55 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-5
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-5 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if ! grep -qi "AddType x-httpd-php*" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.6, changing to 5.4.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                echo -e "AddType x-httpd-php55 .php\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-5
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-5 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi
ChangePHPVersion
}

##
# Function to change the PHP version to 5.6 and create an optimized PHP.ini file
##
function changePHPTo5.6(){
        whichletter="$(pwd | awk -F/ '{print $4}')"
        whichdomain="$(pwd | awk -F/ '{print $5}')"

if grep -qi "AddType x-httpd-php56 .php" ~/public_html/.htaccess 2>/dev/null
then
    echo -ne "$(ColorGreen '- The current PHP version is 5.6, nothing to do.')
";
fi

if ! grep -qi "AddType x-httpd-ph*" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.6, nothing to do.')
";
fi

if grep -qi "AddType x-httpd-php53 .php" ~/public_html/.htaccess 2>/dev/null
then
                echo "$(ColorGreen 'The current PHP version is 5.3,changing to 5.6')
                ";
                cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
        grep -i 'AddType x-httpd-php53 .php'  ~/public_html/.htaccess | sed -i 's#php53 #php56 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-6
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been 
created.')
";
                mv php.ini-5-6 php.ini
        echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
        elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
        else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php54 .php" ~/public_html/.htaccess 2>/dev/null
then
                echo "$(ColorGreen 'The current PHP version is 5.4,changing to 5.6')
                ";
                cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php54 .php'  ~/public_html/.htaccess | sed -i 's#php54 #php56 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-6
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-6 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
         elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php55 .php" ~/public_html/.htaccess 2>/dev/null
then
                echo "$(ColorGreen 'The current PHP version is 5.5,changing to 5.6')
                ";
                cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php55 .php'  ~/public_html/.htaccess | sed -i 's#php55 #php56 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-6
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-6 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php7 .php" ~/public_html/.htaccess 2>/dev/null
then
                echo "$(ColorGreen 'The current PHP version is 7,changing to 5.6')
                ";
                cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php7 .php'  ~/public_html/.htaccess | sed -i 's#php7 #php56 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-6
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-6 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php71 .php" ~/public_html/.htaccess 2>/dev/null
then
                echo "$(ColorGreen 'The current PHP version is 7.1,changing to 5.6')
                ";
                cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php71 .php'  ~/public_html/.htaccess | sed -i 's#php71 #php56 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-6
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-6 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
        elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
        else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi
ChangePHPVersion
}


##
# Function to change the PHP version to 7 and create an optimized PHP.ini file
##
function changePHPTo7(){
        whichletter="$(pwd | awk -F/ '{print $4}')"
        whichdomain="$(pwd | awk -F/ '{print $5}')"

if grep -qi "AddType x-httpd-php7 .php" ~/public_html/.htaccess 2>/dev/null
then
    echo -ne "$(ColorGreen '- The current PHP version is 7, nothing to do.')
";
fi

if grep -qi "AddType x-httpd-php53 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.3, changing to 7.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php53 .php'  ~/public_html/.htaccess | sed -i 's#php53 #php7 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-7
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-7 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php54 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.4, changing to 7.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php54 .php'  ~/public_html/.htaccess | sed -i 's#php54 #php7 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-7
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-7 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php55 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.5, changing to 7.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php55 .php'  ~/public_html/.htaccess | sed -i 's#php55 #php7 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-7
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-7 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php56 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.6, changing to 7.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php56 .php'  ~/public_html/.htaccess | sed -i 's#php56 #php7 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-7
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-7 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php71 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 7.1, changing to 7.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php71 .php'  ~/public_html/.htaccess | sed -i 's#php71 #php7 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-7
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-7 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if ! grep -qi "AddType x-httpd-php*" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.6, changing to 7.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                echo -e "AddType x-httpd-php7 .php\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-7
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-7 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi
ChangePHPVersion
}

##
# Function to change the PHP version to 7.1 and create an optimized PHP.ini file
##
function changePHPTo71(){
        whichletter="$(pwd | awk -F/ '{print $4}')"
        whichdomain="$(pwd | awk -F/ '{print $5}')"

if grep -qi "AddType x-httpd-php71 .php" ~/public_html/.htaccess 2>/dev/null
then
    echo -ne "$(ColorGreen '- The current PHP version is 7.1, nothing to do.')
";
fi

if grep -qi "AddType x-httpd-php53 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.3, changing to 7/1.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php53 .php'  ~/public_html/.htaccess | sed -i 's#php53 #php71 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-7
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-7 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php54 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.4, changing to 7.1.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php54 .php'  ~/public_html/.htaccess | sed -i 's#php54 #php71 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-7
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-7 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php55 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.5, changing to 7.1.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php55 .php'  ~/public_html/.htaccess | sed -i 's#php55 #php71 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-7
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-7 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php56 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.6, changing to 7.1.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php56 .php'  ~/public_html/.htaccess | sed -i 's#php56 #php71 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-7
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-7 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php7 .php" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 7, changing to 7.1.')
";
        cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php7 .php'  ~/public_html/.htaccess | sed -i 's#php7 #php71 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-7
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-7 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi
ChangePHPVersion
}


##
# Function that installs ioncube for PHP 7 on the Cloud Platform
# Use it when you need the lastest version of ioncube
##

function install_ioncube_php70() {

        if ! grep -q "AddType x-httpd-php7" ~/public_html/.htaccess 2>/dev/null ; then
                echo $(ColorRed  "This is only for PHP 7.0, and you are running a different PHP version!")
	WrongCommand	
	CloudMenu
        fi

        whichletter="$(pwd | awk -F/ '{print $4}')"
        whichdomain="$(pwd | awk -F/ '{print $5}')"
        PHP_VER="$(if grep -q "AddType x-httpd-php7" ~/.htaccess 2>/dev/null ; then
           echo "7.0";
        fi
        )"


        # Function to Download and extract 64-bit files

        clear
            echo "$(ColorGreen 'Downloading the ioncube archieve')";
                echo ""
            wget -q -O ~/ioncube_loaders_lin_x86-64.tar.gz https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz


        # Extract the archieve
                sleep 2s
            echo "$(ColorGreen 'Extracting archieve')";
            echo ""
                tar xvf ~/ioncube_loaders_lin_x86-64.tar.gz

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
	        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        	then
                	echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
	        elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
		else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
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
	    echo "$(ColorGreen 'Done, Ioncube has been successfully installed')";
	    echo ""

CloudMenu
}

##
# Function to change the PHP version to 5.6 and create an optimized PHP.ini file
##
function MagentoChangePHPto5.6(){
        whichletter="$(pwd | awk -F/ '{print $4}')"
        whichdomain="$(pwd | awk -F/ '{print $5}')"

if grep -qi "AddType x-httpd-php56 .php" ~/public_html/.htaccess 2>/dev/null
then
    echo -ne "$(ColorGreen '- The current PHP version is 5.6, nothing to do.')
";
fi

if ! grep -qi "AddType x-httpd-ph*" ~/public_html/.htaccess 2>/dev/null
then
        echo -ne "$(ColorGreen '- The current PHP version is 5.6, nothing to do.')
";
fi

if grep -qi "AddType x-httpd-php53 .php" ~/public_html/.htaccess 2>/dev/null
then
                echo "$(ColorGreen 'The current PHP version is 5.3,changing to 5.6')
                ";
                cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
        grep -i 'AddType x-httpd-php53 .php'  ~/public_html/.htaccess | sed -i 's#php53 #php56 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-6
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been 
created.')
";
                mv php.ini-5-6 php.ini
        echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
        elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
        else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php54 .php" ~/public_html/.htaccess 2>/dev/null
then
                echo "$(ColorGreen 'The current PHP version is 5.4,changing to 5.6')
                ";
                cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php54 .php'  ~/public_html/.htaccess | sed -i 's#php54 #php56 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-6
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-6 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
         elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php55 .php" ~/public_html/.htaccess 2>/dev/null
then
                echo "$(ColorGreen 'The current PHP version is 5.5,changing to 5.6')
                ";
                cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php55 .php'  ~/public_html/.htaccess | sed -i 's#php55 #php56 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-6
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-6 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php7 .php" ~/public_html/.htaccess 2>/dev/null
then
                echo "$(ColorGreen 'The current PHP version is 7,changing to 5.6')
                ";
                cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php7 .php'  ~/public_html/.htaccess | sed -i 's#php7 #php56 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-6
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-6 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
    elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
    else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi

if grep -qi "AddType x-httpd-php71 .php" ~/public_html/.htaccess 2>/dev/null
then
                echo "$(ColorGreen 'The current PHP version is 7.1,changing to 5.6')
                ";
                cd ~/public_html/
                mv php.ini php.ini-old 2>/dev/null
                cd
                mv php.ini php.ini-old 2>/dev/null
                grep -i 'AddType x-httpd-php71 .php'  ~/public_html/.htaccess | sed -i 's#php71 #php56 #' ~/public_html/.htaccess 2>/dev/null
                wget -Nq http://paragon.alexgeorgiev.net/phpini/php.ini-5-6
                echo -ne "$(ColorGreen '- Creating a new optimized php.ini file. Memory_limit has been set to 1024M, max_execution_time has been set to 900, max_input_vars has been seto to 8000 and error_logging has been
created.')
";
                mv php.ini-5-6 php.ini
                echo "
error_log = /var/sites/${whichletter}/${whichdomain}/public_html/error_log" >>  ~/php.ini
        if grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini" ~/public_html/.htaccess 2>/dev/null
        then
                echo -ne "$(ColorGreen '- There is a valid suPHP_ConfigPath in public_html/.htaccess-skipping')
";
        elif grep -qi "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/public_html/*" ~/public_html/.htaccess 2>/dev/null
                then
                        grep -i 'suPHP'  ~/public_html/.htaccess | sed -i 's#/public_html##' ~/public_html/.htaccess 2>/dev/null
                        echo -ne "$(ColorGreen '- The suPHP_ConfigPath in public_html/.htaccess has been configured')
";
        else
                echo -ne "$(ColorGreen "- Couldn't find a valid SuPHP_ConfigPath, creating a new one in public_html/.htaccess.")
";
                echo -e "suPHP_ConfigPath /var/sites/${whichletter}/${whichdomain}/php.ini\n$(cat ~/public_html/.htaccess 2>/dev/null)" > ~/public_html/.htaccess 2>/dev/null

        fi
fi
}

function mage2_install_cloud() {
        MagentoChangePHPto5.6
trap command SIGINT
        echo -ne "$(ColorGreen "-This is probably the quickest way of deploying Magento 2 files on the Cloud")
";
        echo -ne "$(ColorGreen "-Please note that you would still need to create a Database and a Database User!")
";
        echo ""
        unset empty
        while [ -z $empty ]; do
                echo -ne "$(ColorGreen "Is the public_html folder empty?[yes/no]")
";
                read empty
                echo -ne "$(ColorGreen "Are you 100% sure that the public_html folder is empty?")
";
                read empty
                if [ ! $empty == yes ]; then
                echo -ne "$(ColorGreen "Make sure that the public_html folder is empty before installing Magento!")
";
                exit 0
                fi
        done
    cd ~/public_html
        wget http://wpcli.bobbyiliev.com/magento2/Magento-CE-2.1.7-2017-05-30-01-54-40.tar.gz
        echo -ne "$(ColorGreen "Extracting magento files ... This might take a while, go make yourself a cup of coffee!")
";
        echo -ne "$(ColorGreen "Also go ahead and create a database, you would need it once the files have been uploaded!")
";
        tar -xzf Magento-CE-2.1.7-2017-05-30-01-54-40.tar.gz

        echo "CheckSpelling Off" >> ~/.htaccess
        echo -ne "$(ColorGreen "Magento 2 files have been deployed at $(pwd) visit the site and complete the installation!")
";
        echo -ne "$(ColorRed "IMPORTANT !!!")";
        echo -ne "$(ColorGreen "Under the advanced settings tab make sure that you select ")";
        echo -ne "$(ColorRed "DB ")";
        echo -ne "$(ColorGreen "as the session handler otherwise your install will fail!")
";

trap - SIGINT
CloudQuickInstallMenu
}

##
# Function that checks the Apache error log for a specific domain name
# Use it when you have a 500 erorr
##

function domainhttpderrors() {
	unset domainerrors
        while [ -z $domainerrors ]; do
        echo -ne "
Please type the domain or type exit to return: (example.com): "
        read domainerrors
        done
        if [ $domainerrors = "exit" ]; then
        MenuAcess
        else
        echo -ne ""
        echo -ne ""
        fi
	count=$(grep $domainerrors /usr/local/apache/logs/error_log | wc -l)
        if [ $count -ne 0 ]; then
                grep $domainerrors /usr/local/apache/logs/error_log
        else
            	echo -ne "$(ColorRed 'No results found! Try another option.')
";
        fi
        echo -ne ""
        echo -ne ""
       	MenuAcess
}

##
# Function that checks the Apache error log for a specific cPanel username
# Use it when you have 500 error and debuging
##

function userhttpderrors() {
        unset usererrors
        while [ -z $usererrors ]; do
        echo -ne "
Please type the cPanel username or type exit to return: (exmapleuser): "
	read usererrors
        done
        if [ $usererrors = "exit" ]; then
        MenuAcess
        else
	echo -ne ""
	echo -ne ""
	fi
	count=$(grep $usererrors /usr/local/apache/logs/error_log | wc -l)
	if [ $count -ne 0 ]; then
		grep $usererrors /usr/local/apache/logs/error_log
	else
		echo $(ColorRed 'No results found! Try another option.')
	fi
	echo -ne ""
	echo -ne ""
        MenuAcess
}



###########################
###  Quick Access Menu  ###
###########################
 
##
# Access Logs Menu
##
MenuAcess(){
if [[ ! -f /etc/userdomains ]]; then
echo $(ColorRed 'You are not on cPanel')
WrongCommand
MainMenu
else
executionTime=`date +%Y-%m-%d:%H:%M:%S`

            	ColorGreen "        "
echo -ne "
Choose the information you need regardin Access Logs

$(ColorGreen '1)') GET/POST requests for a specific website
$(ColorGreen '2)') GET/POST requests from particualr IP for a specific website
$(ColorGreen '3)') GET/POST requests + IP addresses for every website on the server
$(ColorGreen '4)') GET/POST requests for every website on the server
$(ColorGreen '5)') List all of the Apache errors for a specific domain
$(ColorGreen '6)') List all of the Apache errors for a specific cPanel username
$(ColorGreen '0)') Back to Main Menu

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
		1) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=AccessLogsForDomain\&Server=$server\&Path=$location ; fi ; MenuAcessDomain;;
		2) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=AccessLogsFromSpecificIPForDomain\&Server=$server\&Path=$location ; fi ; MenuAcessSpecificIPForDomain;;
                3) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=AccessAndIPLogs\&Server=$server\&Path=$location ; fi ; access_and_ip_logs;;
                4) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=OnlyAccessLogs\&Server=$server\&Path=$location ; fi ; OnlyAccessLogs;;
                5) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=ApacheErrorsWebSite\&Server=$server\&Path=$location ; fi ; domainhttpderrors;;
                6) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=ApacheErrorsUsername\&Server=$server\&Path=$location ; fi ; userhttpderrors;;
		0) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=MainMenu\&Server=$server\&Path=$location ; fi ; MainMenu;;
		*) echo -e $red"Wrong command."$clear; MenuAcess;;
        esac
fi
}


##
# Cloud Menu
##
CloudMenu(){
if [[ ! $(pwd | grep '/var/sites/') ]]; then
echo $(ColorRed 'You are not on the Cloud')
WrongCommand
MainMenu
else
ExecutionTime=`date +%Y-%m-%d:%H:%M:%S`
                ColorGreen "        "
echo -ne "
Cloud Menu

$(ColorRed 'Please note that you should run those only on the Cloud!!!')

$(ColorGreen '1)') One click installations
$(ColorGreen '2)') PHP configurations and settigs
$(ColorGreen '3)') Check if a PHP extension is enabled on the server.
$(ColorGreen '4)') Check if a PHP function is enabled on the server.
$(ColorGreen '5)') Generate random password
$(ColorGreen '6)') Install Ioncube for a website using PHP 7
$(ColorGreen '0)') Back to Main Menu

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
                1) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=CloudQuickInstallMenu\&Server=$server\&Path=$location ; fi ; CloudQuickInstallMenu;;
		2) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=PHPchangesMenu\&Server=$server\&Path=$location ; fi ; ChangePHPVersion;;
                3) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=IsExtensionEnabled\&Server=$server\&Path=$location ; fi ; is_extensionCloud;;
                4) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=IsFunctionnEnabled\&Server=$server\&Path=$location ; fi ; is_functionCloud;;
		5) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=RandomPass\&Server=$server\&Path=$location ; fi ; randompass_cloud;;
		6) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=IonCubeInstaller\&Server=$server\&Path=$location ; fi ; install_ioncube_php70;;
		0) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=MainMenu\&Server=$server\&Path=$location ; fi ; MainMenu;;
                *) echo -e $red"Wrong command."$clear; CloudMenu;;
        esac
fi
}

##
# The installation section in the Cloud Menu
##
CloudQuickInstallMenu(){
if [[ ! $(pwd | grep '/var/sites/') ]]; then
echo $(ColorRed 'You are not on the Cloud')
WrongCommand
MainMenu
else
ExecutionTime=`date +%Y-%m-%d:%H:%M:%S`
                ColorGreen "        "
echo -ne "
Installations on the Cloud

$(ColorRed 'Please note that you should run those only on the Cloud!!!')

$(ColorGreen '1)') Install wp-cli on the Cloud
$(ColorGreen '2)') Install composer on the Cloud
$(ColorGreen '3)') Install laravel on the Cloud
$(ColorGreen '4)') Install Magento 2.1.7 on the Cloud
$(ColorGreen '0)') Back to the Cloud Main Menu

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
                1) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=InstallwpCLI\&Server=$server\&Path=$location ; fi ; wp_cli_cloud_install;;
                2) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=InstallComposer\&Server=$server\&Path=$location ; fi ; composer_cloud_install;;
                3) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=InstallLaravel\&Server=$server\&Path=$location ; fi ; laravel_cloud_installer;;
                4) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=InstallMagento2OnTheCloud\&Server=$server\&Path=$location ; fi ; mage2_install_cloud;;
		0) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; fi ; CloudMenu;;
		*) echo -e $red"Wrong command."$clear; CloudQuickInstallMenu;;
        esac
fi
}

##
# PHP section in the Cloud Menu
##
ChangePHPVersion(){
if [[ ! $(pwd | grep '/var/sites/') ]]; then
echo $(ColorRed 'You are not on the Cloud')
WrongCommand
MainMenu
else
ExecutionTime=`date +%Y-%m-%d:%H:%M:%S`
                ColorGreen "        "
echo -ne "

Change PHP version

$(ColorGreen '1)') Change PHP version to 5.3
$(ColorGreen '2)') Change PHP version to 5.4
$(ColorGreen '3)') Change PHP version to 5.5
$(ColorGreen '4)') Change PHP version to 5.6
$(ColorGreen '5)') Change PHP version to 7.0
$(ColorGreen '6)') Change PHP version to 7.1
$(ColorGreen '7)') Deploy an optimized php.ini for the used PHP version.
$(ColorGreen '8)') Change the Shell PHP version to 7
$(ColorGreen '0)') Back To Main Menu.

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
                1) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=ChangePHPVersionTo5.3\&Server=$server\&Path=$location ; fi ; changePHPTo5.3;;
               	2) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=ChangePHPVersionTo5.4\&Server=$server\&Path=$location ; fi ; changePHPTo5.4;;
                3) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=ChangePHPVersionTo5.5\&Server=$server\&Path=$location ; fi ; changePHPTo5.5;;
               	4) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=ChangePHPVersionTo5.6\&Server=$server\&Path=$location ; fi ; changePHPTo5.6;;
                5) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=ChangePHPVersionTo7\&Server=$server\&Path=$location ; fi ; changePHPTo7;;
            	6) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=ChangePHPVersionTo7.1\&Server=$server\&Path=$location ; fi ; changePHPTo71;;
		7) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=Deploy_optimized_PHP_ini\&Server=$server\&Path=$location ; fi ; DeployPHPini;;
                8) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=ChangeShellPHPVersion\&Server=$server\&Path=$location ; fi ; ChangeShellPHP;;
               	0) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=MainMenu\&Server=$server\&Path=$location ; fi ; CloudMenu;;
                *) echo -e $red"Wrong command."$clear; ChangePHPVersion;;
        esac
fi
}

##
#  Section in the Access Logs Menu that ask for a specific domain 
##
MenuAcessDomain(){

	echo -ne "
Please type the domain (example.com): "
                read responsedomain
		SpecificDomainAccessLogs
MenuAcess
}

##
#  Section in the Access Logs Menu that ask for a specific domain 
##
MenuAcessSpecificIPForDomain(){

        echo -ne "
Please type the domain (example.com): "
                read responsedomain
 echo -ne "
Please type the IP: "
		read responseIP 
		SpecificDomainAccessLogsWithIP
MenuAcess
}

##
# Email Features Menu
##
EmailsMenu(){
if [[ ! -f /etc/userdomains ]]; then
echo $(ColorRed 'You are not on cPanel')
WrongCommand
MainMenu
else
ExecutionTime=`date +%Y-%m-%d:%H:%M:%S`

            	ColorGreen "        "
echo -ne "
Choose the information you need regarding Email Logs

$(ColorGreen '1)') Receive a sorted list of all the email senders in the exim mail queue.
$(ColorGreen '2)') This option will display the directories from which the emails are being sent.
$(ColorGreen '3)') This option will check for emails sent via php script.
$(ColorGreen '4)') This option will display the users which were sending out emails within their directories.
$(ColorGreen '5)') It shows the IPs which were sending emails via port 25..
$(ColorGreen '6)') In order to find “nobody” spamming, use this option..
$(ColorGreen '7)') The above option is valid only if the spamming is currently in progress If not use this otpion..
$(ColorGreen '8)') Summary of the mails in the mail queue.
$(ColorGreen '0)') Back to Main Menu.

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
                1) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=Exim1ListofAllEmailSenders\&Server=$server\&Path=$location ; fi ; showexim ;;
                2) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=Exim2EximSpamDirs\&Server=$server\&Path=$location ; fi ; originate;;
                3) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=Exim3EximPHPSpam\&Server=$server\&Path=$location ; fi ; originate2;;
                4) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=Exim4EximUsersSpam\&Server=$server\&Path=$location ; fi ; whichphpscript;;
                5) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=Exim5IPsOnPort25\&Server=$server\&Path=$location ; fi ; getnetstat;;
                6) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=Exim6NobodySpam\&Server=$server\&Path=$location ; fi ; nobodyspam;;
                7) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=Exim7SpamInProgress\&Server=$server\&Path=$location ; fi ; nobodyspamafter;;
                8) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=Exim8MailQueue\&Server=$server\&Path=$location ; fi ; showeximsum;;
                0) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=MainMenu\&Server=$server\&Path=$location ; fi ; MainMenu;;
		*) echo -e $red"Wrong command."$clear; EmailsMenu;;
        esac
fi
}

##
# SysAdmins Menu
##
SysAdminsMenu(){
    #unset syspass
    while [ -z $syspass ] ; do
    echo "Only for SysAdmins! Please enter the secret password or type exit:"
    read syspass
	if [ $syspass = "exit" ]; then
               	unset syspass
                MainMenu
	elif [ $syspass != "SysAdmins" ]; then
		echo "Wrong Password!"
		unset syspass
	fi
    done
    if [ $syspass = "SysAdmins" ]; then
	if [[ $(pwd | grep '/var/sites/') ]]; then
	echo $(ColorRed 'You are not on cPanel')
	WrongCommand
	MainMenu
	else
ExecutionTime=`date +%Y-%m-%d:%H:%M:%S`
                ColorGreen "        "
echo -ne "

Choose the information you need regarding MySQL

$(ColorGreen '1)') List MySQL sleeping Processes.
$(ColorGreen '2)') Kill all MySQL sleeping Processes that have been sleeping for more that 60 seconds.
$(ColorGreen '3)') Show full processlist.
$(ColorGreen '4)') Kill all MySQL sleeping Processes "for" a specific user.
$(ColorGreen '0)') Back To Main Menu.

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
                1) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=List_sleeping_mysql_processes\&Server=$server\&Path=$location ; fi ; list_sleeping_mysql_admins;;
                2) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=Kill_mysql_sleeping_processes\&Server=$server\&Path=$location ; fi ; kill_mysql_sleeping_proc;;
                3) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=Show_ll_rocesses\&Server=$server\&Path=$location ; fi ; show_full_processlist_admins;;
                4) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=Kill_mysql_sleeping_processes_for_specific_user\&Server=$server\&Path=$location ; fi ; kill_mysql_sleeping_proc_user;;
                0) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=MainMenu\&Server=$server\&Path=$location ; fi ; MainMenu;;
                *) echo -e $red"Wrong command."$clear; SysAdminsMenu;;
        esac

	fi
    fi
}

##
# The MySQL Menu
##
MySQLMenu(){
#check_mysql_startup_info
if [[ $(pwd | grep '/var/sites/') ]]; then
echo $(ColorRed 'You are not on cPanel')
WrongCommand
MainMenu
else
ExecutionTime=`date +%Y-%m-%d:%H:%M:%S`
                ColorGreen "        "
echo -ne "

Choose the information you need regarding MySQL

$(ColorGreen '1)') Show MySQL status and Uptime.
$(ColorGreen '2)') List MySQL sleeping Processes.
$(ColorGreen '3)') Show full processlist.
$(ColorGreen '0)') Back To Main Menu.

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
                2) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=List_sleeping_mysql_processes\&Server=$server\&Path=$location ; fi ; list_sleeping_mysql;;
                3) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=Show_ll_rocesses\&Server=$server\&Path=$location ; fi ; show_full_processlist;;
 	        1) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=MySQL_status_and_connections\&Server=$server\&Path=$location ; fi ; mysql_status;;
                0) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=MainMenu\&Server=$server\&Path=$location ; fi ; MainMenu;;
		*) echo -e $red"Wrong command."$clear; MySQLMenu;;
        esac
fi
}

ToolsMenu(){
if [[ ! -f /etc/userdomains ]]; then
echo $(ColorRed 'You are not on cPanel')
WrongCommand
MainMenu
else
ExecutionTime=`date +%Y-%m-%d:%H:%M:%S`
                ColorGreen "        "
echo -ne "

Cool Tools

$(ColorGreen '1)') Check if a PHP extension is enabled on the server.
$(ColorGreen '2)') Check if a PHP function is enabled on the server.
$(ColorGreen '3)') Generate a random password
$(ColorGreen '4)') Live Monitor of the CPU.
$(ColorGreen '5)') Find files larger than 100MB in /home/
$(ColorGreen '6)') Check the EasyApache Version
$(ColorGreen '0)') Back To Main Menu.

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
                1) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=IsExtensionEnabled\&Server=$server\&Path=$location ; fi ; is_extension;;
                2) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=IsFunctionEnabled\&Server=$server\&Path=$location ; fi ; is_function;;
		3) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=RandomPass\&Server=$server\&Path=$location ; fi ; randompass;;
		4) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=MonitorCPU\&Server=$server\&Path=$location ; fi ; MonitorCpu;;
		5) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=FindLargeFiles\&Server=$server\&Path=$location ; fi ; FindLargeFiles;;
		6) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=EAversion\&Server=$server\&Path=$location ; fi ; EAversion;;
                0) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=MainMenu\&Server=$server\&Path=$location ; fi ; MainMenu;;
		*) echo -e $red"Wrong command."$clear; ToolsMenu;;
        esac
fi
}

DDoSMenu(){
if [[ $(pwd | grep '/var/sites/') ]]; then
echo $(ColorRed 'You are not on cPanel')
WrongCommand
MainMenu
else
ExecutionTime=`date +%Y-%m-%d:%H:%M:%S`
                ColorGreen "        "
echo -ne "
Web Traffic Menu

$(ColorGreen '1)') Lists the Ips which are connected to server and how many connections exist from each IP
$(ColorGreen '2)') Lists the users which are running the most processes at the moment - the top 5 users
$(ColorGreen '3)') Function that lists the total process running by the users
$(ColorGreen '4)') Function that shows the % CPU usage at the moment
$(ColorGreen '5)') Function that lists all the active connections for a specific port defined by the script user
$(ColorGreen '6)') Resource usage per user
$(ColorGreen '0)') Back To Main Menu

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
		1) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=ActiveConn\&Server=$server\&Path=$location ; fi ; ActiveConn;;
                2) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=TopUsers\&Server=$server\&Path=$location ; fi ; TopUsers;;
                3) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=AllUsers\&Server=$server\&Path=$location ; fi ; AllUsers;;
                4) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=CPUusage\&Server=$server\&Path=$location ; fi ; CurrentCPUusage;;
                5) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=ConnectionsOnSpecPort\&Server=$server\&Path=$location ; fi ; GetPortConn;;
		6) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=ResourceUsagePerUser\&Server=$server\&Path=$location ; fi ; Zack;;
                0) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=MainMenu\&Server=$server\&Path=$location ; fi ; MainMenu;;
                *) echo -e $red"Wrong command."$clear; WrongCommand;;
        esac
fi
}

#################
# The Main Menu #
#################
MainMenu(){
tput clear
while [ -z $paruser ] ; do
    	echo ""
	echo "To start please enter your paruser:"
    read paruser
	if [[ ! $paruser =~ [a-z_]+$ ]] || [[ ! $paruser =~ ^par[a-z_]+$ ]]  ; then
		unset paruser
		echo "Don't cheat! Enter your correct paruser!"
	fi
done

                ColorGreen "        "
echo -ne "
Main Menu

$(ColorGreen '1)') Access Logs Menu
$(ColorGreen '2)') SPAM Scan Menu
$(ColorGreen '3)') MySQL Menu
$(ColorGreen '4)') Web Traffic Menu
$(ColorGreen '5)') Handy Tools
$(ColorGreen '6)') Cloud Tools
$(ColorGreen '0)') Exit

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
                1) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=MenuAccess\&Server=$server\&Path=$location ; fi ; MenuAcess;;
		2) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=EmailsMenu\&Server=$server\&Path=$location ; fi ; EmailsMenu;;
		3) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=MySQLMenu\&Server=$server\&Path=$location ; fi ; MySQLMenu;;
		4) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=WebTrafficMenu\&Server=$server\&Path=$location ; fi ; DDoSMenu;;
		5) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=HandyToolsMenu\&Server=$server\&Path=$location ; fi ; ToolsMenu;;
		6) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; fi ; CloudMenu;;
		admins) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=SysAdminsMenu\&Server=$server\&Path=$location ; fi ; SysAdminsMenu;;
		0) if [[ $enablelog == 1 ]] ; then curl ${reportDomain}?user=$paruser\&Date=$executionTime\&Executed=Exit\&Server=$server\&Path=$location ; fi ; Exitmenu;;
		*) echo -e $red"Wrong command."$clear; WrongCommand;;
        esac
}
tput clear
MainMenu
