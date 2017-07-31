#!/bin/bash

# To check max_connections + max_user_connections % total connections 
function check_mysql_conn() {
	#Get MySQL connections value
	allowed=$(mysql -e 'show variables like "max_connections"' | grep 'max_conn' | awk '{print $2}')
	current=$(mysqladmin proc | grep -v Id | grep -v '\-\-\-' | wc | awk '{ print $1}')
	echo "You are using $current of the allowed $allowed MySQL connections"
}

check_mysql_conn
