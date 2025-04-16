#!/bin/bash

#Count number of login attempts from different hosts
#then ask to ban them
#
#The banning process uses the access control files for tcp wrappers
#in order to ban ip addresses flat out.



TMP_FILE="/tmp/ip/ipss.txt"
COUNT_FILE="/tmp/ip/ipsc.txt"

#If attempts are greater than this the
#IP will be banned.
MAX_ATTEMPTS=0
ALLOWED_ATTEMPTS=5 #Allowed amount of login attempts from IP
SINCE_DATE=""

if [ ! -d "/tmp/ip" ]; then
        mkdir /tmp/ip
fi

function display_help() {
	echo -e "Usage: banips command [date]"
	echo -e "Date may be entered in format that 'date -d' allows. E.g. 'April 4, 2025'\n"
	echo -e "Commands"
	echo -e "help\t\tDisplays this help message."
	echo -e "count [date]\tCounts total login attempts since date. If no date specified then count all."
	echo -e "ban [date]\tBan all IPs since date. Will be prompted to give maximum allowed login attempts."
}

function get_date() {
	if [ "$1" = "" ]; then
		SINCE_DATE="2000-01-01"
	elif ! SINCE_DATE=$(date -d $1 +"%Y-%m-%d"); then
		echo "Invalid Date."
		exit 1
	fi
}

#Count login attempts from different IPs and display a list.
function count_ips() {
	journalctl --since=$SINCE_DATE | grep "Failed" | grep -oE "\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b" > $TMP_FILE
}

function display_ips() {
	echo -e "Total failed login attempts: \c"
	echo `wc -l $TMP_FILE | grep -oE "[0-9]*"`
	echo -e "Attempts\tIP"
	sort $TMP_FILE | uniq -c | sort -r > $COUNT_FILE
	sed 's/^\s*//' $COUNT_FILE | sed 's/^[0-9]*/&\t\t/'
}

#Ban the IP address using access control see man hosts_access(5)
#One argument: IP address to ban
function ban_ip() {
	if [ "$(cat /etc/hosts.deny | grep "$1")" = "" ]; then
    	if [ -f "/etc/hosts.deny" ]; then
			echo ALL : $1 : deny >> /etc/hosts.deny
            echo -e "Banning IP \c"
            echo $1
        else
        	echo "/etc/hosts.deny does not exist"
        	exit 1
        fi
    fi
}

#Ask to ban the IPs by user input.
function ask_ban() {
	if [ ! -w /etc/hosts.deny -o ! -r /etc/hosts.deny  ]; then
		echo -e "***Don't have permissions for access control***"
		echo "Set /etc/hosts.deny READ & WRITE permissions"
		exit 1
	fi

	while (( MAX_ATTEMPTS < ALLOWED_ATTEMPTS + 1 )); do
		echo -e "Set max attempts and ban IPs ( >$ALLOWED_ATTEMPTS ): \c"
		read MAX_ATTEMPTS
	done
}

#Ban all IPs that exceed maximum attempts.
function ban_all_ips() {
	cat $COUNT_FILE | while IFS= read -r line; do
		ATTEMPTS=$(echo "$line" | awk '{print $1}')
		if [ $ATTEMPTS -gt $MAX_ATTEMPTS ]; then
			echo -e "Banning IP \c"
			IP="$(echo $line | awk '{print $2}')"
			echo $IP
			ban_ip $IP
		fi
	done

}



case $1 in
"help" | "HELP" )
	display_help
	;;
"count" | "COUNT" )
	get_date $2
	count_ips
	display_ips
	;;
"ban" | "BAN" )
	get_date $2
	ask_ban
	ban_all_ips
	;;
* )
	printf "Invalid Command\n"
	display_help
	;;
esac
