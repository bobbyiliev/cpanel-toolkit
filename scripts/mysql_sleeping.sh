#!/bin/bash

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
}
kill_mysql_sleeping_proc

