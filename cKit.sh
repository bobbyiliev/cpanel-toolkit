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

##
# Function that lists access logs for every website separately
# including POST/GET requests and IP logs. 
##
function access_and_ip_logs() {
for i in $(cat '/etc/userdomains' | grep -v '*' | awk -F":" '{print $1}'); do
                domains=${i};
                username="$(grep ${domains} /etc/userdomains | awk -F": " '{print $2 }' | tail -1)";
		echo "#####################"
                echo "$domains access logs:"
                #cat /home/$username/access-logs/$domains* 2>/dev/null | awk '{print $6 " " $7}' | sort | uniq -c | sort -rn | head
		grep $domains /home/$username/access-logs/* 2>/dev/null | awk '{print $6 " " $7}' | sort | uniq -c | sort -rn | head
                echo "$domains most hits from IP:"
                #cat /home/$username/access-logs/$domains* 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -rn | head
		#grep $domains /home/$username/access-logs/* 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -rn | head
		grep $domains /home/$username/access-logs/* 2>/dev/null | awk -F":" '{print $2}' | awk -F"-" '{print $1}' |sort | uniq -c | sort -rn | head
		echo "#####################"
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
        	echo "#####################"
	        echo "$domains access logs: "
                #cat /home/$username/access-logs/$domains* 2>/dev/null | awk '{print $6 " " $7}' | sort | uniq -c | sort -rn | head 
		grep $domains /home/$username/access-logs/* 2>/dev/null | awk '{print $6 " " $7}' | sort | uniq -c | sort -rn | head
		echo "#####################"
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
        	        echo "$domains access logs"
                	#cat /home/$username/access-logs/$domains* 2>/dev/null | awk '{print $6 " " $7}' | sort | uniq -c | sort -rn | head
			grep $domains /home/$username/access-logs/* 2>/dev/null | awk '{print $6 " " $7}' | sort | uniq -c | sort -rn | head
        	        echo "$domains most hits from IP:"
	                grep $domains /home/$username/access-logs/* 2>/dev/null | awk -F":" '{print $2}' | awk -F"-" '{print $1}' |sort | uniq -c | sort -rn | head
                	echo "#####################"
		}
		fi
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
MySQLMenu
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
MySQLMenu
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
wget --no-check-certificate -O IsExtension.php https://raw.githubusercontent.com/bobbyiliev/cpanel-toolkit/master/dev/IsExtension.txt

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
        date +%s | sha256sum | base64 | head -c 14 ; echo
        echo "Do you want to genrate stronger password[yes/no]"
        read answer
        if [ ! -z $answer ] && [ $answer = "yes" ]; then
        date +%s | sha256sum | base64 | head -c 20 ; echo
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
        date +%s | sha256sum | base64 | head -c 14 ; echo
        echo "Do you want to genrate stronger password[yes/no]"
        read answer
        if [ ! -z $answer ] && [ $answer = "yes" ]; then
        date +%s | sha256sum | base64 | head -c 20 ; echo
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
    touch "~/.bashrc" 2>/dev/null
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
if grep -q "alias php=/usr/bin/php-*" ".bashrc" 
then
echo -e'alias php=/usr/bin/php-7.0'  >> ~/.bashrc
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

$(ColorGreen '1)') GET/POST Requests + IP addresses for every website on the VPS
$(ColorGreen '2)') GET/POST Requests for every website on the VPS
$(ColorGreen '3)') GET/POST Requests for a specific website
$(ColorGreen '0)') Back to Main Menu

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
                1) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=AccessAndIPLogs\&Server=$server\&Path=$location ; access_and_ip_logs;;
                2) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=OnlyAccessLogs\&Server=$server\&Path=$location ; OnlyAccessLogs;;
		3) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=AccessLogsForDomain\&Server=$server\&Path=$location ; MenuAcessDomain;;
		0) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=MainMenu\&Server=$server\&Path=$location ; MainMenu;;
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

$(ColorGreen '1)') Install wp-cli on the Cloud
$(ColorGreen '2)') Install composer on the Cloud
$(ColorGreen '3)') Install laravel on the Cloud
$(ColorGreen '4)') Generate random password
$(ColorGreen '5)') Check if a PHP extension is enabled on the server.
$(ColorGreen '6)') Check if a PHP function is enabled on the server.
$(ColorGreen '7)') Change the Shell PHP version to 7
$(ColorGreen '0)') Back to Main Menu

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
                1) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=InstallwpCLI\&Server=$server\&Path=$location ; wp_cli_cloud_install;;
                2) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=InstallComposer\&Server=$server\&Path=$location ; composer_cloud_install;;
                3) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=InstallLaravel\&Server=$server\&Path=$location ; laravel_cloud_installer;;
		4) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=RandomPass\&Server=$server\&Path=$location ; randompass_cloud;;
                5) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=IsExtensionEnabled\&Server=$server\&Path=$location ; is_extension;;
                6) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=IsFunctionnEnabled\&Server=$server\&Path=$location ; is_function;;
		7) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=ChangeShellPHPVersion\&Server=$server\&Path=$location ; ChangeShellPHP;;
		0) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=MainMenu\&Server=$server\&Path=$location ; MainMenu;;
                *) echo -e $red"Wrong command."$clear; CloudMenu;;
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
                1) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; showexim ;;
                2) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; originate;;
                3) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; originate2;;
                4) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; whichphpscript;;
                5) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; getnetstat;;
                6) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; nobodyspam;;
                7) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; nobodyspamafter;;
                8) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; showeximsum;;
                0) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; MainMenu;;
		*) echo -e $red"Wrong command."$clear; EmailsMenu;;
        esac
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

$(ColorGreen '1)') List MySQL sleeping Processes.
$(ColorGreen '2)') Kill all MySQL sleeping Processes.
$(ColorGreen '3)') Show full processlist.
$(ColorGreen '4)') Show MySQL status and Uptime.
$(ColorGreen '5)') Kill all MySQL sleeping Processes "for" a specific user.
$(ColorGreen '0)') Back To Main Menu.

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
                1) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=List_sleeping_mysql_processes\&Server=$server\&Path=$location ; list_sleeping_mysql;;
                2) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=Kill_mysql_sleeping_processes\&Server=$server\&Path=$location ; kill_mysql_sleeping_proc;;
                3) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=Show_ll_rocesses\&Server=$server\&Path=$location ; show_full_processlist;;
 	        4) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=MySQL_status_and_connections\&Server=$server\&Path=$location ; mysql_status;;
		5) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=Kill_mysql_sleeping_processes_for_specific_user\&Server=$server\&Path=$location ; kill_mysql_sleeping_proc_user;;
                0) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=MainMenu\&Server=$server\&Path=$location ; MainMenu;;
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
                1) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; is_extension;;
                2) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; is_function;;
		3) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; randompass;;
		4) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; MonitorCpu;;
		5) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; FindLargeFiles;;
		6) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; EAversion;;
                0) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; MainMenu;;
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
$(ColorGreen '0)') Back To Main Menu

$(ColorBlue 'Choose an option:') "
                read a
                case $a in
		1) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; ActiveConn;;
                2) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; TopUsers;;
                3) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; AllUsers;;
                4) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; CurrentCPUusage;;
                5) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; GetPortConn;;
                0) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; MainMenu;;
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
    echo "To start please enter your paruser:"
    read paruser
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
                1) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=MenuAccess\&Server=$server\&Path=$location ; MenuAcess;;
		2) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=EmailsMenu\&Server=$server\&Path=$location ; EmailsMenu;;
		3) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=MySQLMenu\&Server=$server\&Path=$location ; MySQLMenu;;
		4) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=WebTrafficMenu\&Server=$server\&Path=$location ; DDoSMenu;;
		5) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=HandyToolsMenu\&Server=$server\&Path=$location ; ToolsMenu;;
		6) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=CloudMenu\&Server=$server\&Path=$location ; CloudMenu;;
		0) curl http://wpcli.bobbyiliev.com/ckit/log.php?user=$paruser\&Date=$executionTime\&Executed=Exit\&Server=$server\&Path=$location ; Exitmenu;;
		*) echo -e $red"Wrong command."$clear; WrongCommand;;
        esac
}
tput clear
MainMenu
