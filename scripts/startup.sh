#!/bin/bash

function welcome() {
	echo "### Some Useful Information ###"

	echo "The server is using about $(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage "%"}') of its CPU  Power"

	echo "Total of $(free -mh | grep Mem | awk '{ print $2 }') RAM installed"

	echo "Total of $(lscpu | grep -v 'node' | grep 'CPU(s):' | awk '{ print $2 }') CPU(s)"

	echo "OS: $(cat /etc/redhat-release)"
}

welcome
