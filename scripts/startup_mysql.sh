#!/bin/bash

# To check max_connections + max_user_connections % total connections
function check_mysql_conn() {
	#Get MySQL connections value
	allowed=$(mysql -e 'show variables like "max_connections"' | grep 'max_conn' | awk '{print $2}')
	current=$(mysqladmin proc | grep -v Id | grep -v '\-\-\-' | wc | awk '{ print $1}')
	percent=$(awk "BEGIN { pc=100*${current}/${allowed}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
	alright=65;
	echo "You are using $current of the allowed $allowed MySQL connections"
	if [ "$percent" -lt "$alright" ]; then
		echo "It is OK, you are using only ${percent}% of the allowed MySQL connections";
	elif [[ ${percent} -gt 65 ]] && [[ ${percent} -lt 85 ]] ; then
		echo "Be careful! You are using ${percent} of the allowed MySQL connections";
	elif [[ $percent -gt 90 ]]; then
		echo "Attention! Check with your friendly SysOps! The server is using more than ${percent} of the allowed MySQL connections";
	fi
}

check_mysql_conn
