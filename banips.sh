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

echo -e "Date since (type nothing for entire history) (Use format YYYY-MM-DD)"
read SINCE_DATE

if [ "$SINCE_DATE" = "" ]; then
        SINCE_DATE="2000-01-01"
fi

if [ ! -d "/tmp/ip" ]; then
        mkdir /tmp/ip
fi

echo -e "Counting IPs of failed login attempts...\n"

journalctl --since=$SINCE_DATE | grep "Failed" | grep -oE "\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b" > $TMP_FILE


echo "Attempts | IP"
sort $TMP_FILE | uniq -c | sort -r > $COUNT_FILE
cat $COUNT_FILE

echo -e "\nTotal failed login attempts: \c"
echo `wc -l $TMP_FILE | grep -oE "[0-9]+"`

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


echo ""


if [ ! -w /etc/hosts.deny ]; then
        echo -e "***Don't have permissions for access control***"
        echo "Set /etc/hosts.deny WRITE permissions"
        exit 1
fi

if [ ! -r /etc/hosts.deny ]; then
        echo "***Don't have permissions for access control***"
        echo "Set /etc/hosts.deny READ permissions"
        exit 1
fi


while (( MAX_ATTEMPTS < ALLOWED_ATTEMPTS + 1 )); do
        echo -e "Set max attempts and ban IPs ( >$ALLOWED_ATTEMPTS ): \c"
        read MAX_ATTEMPTS
done


cat $COUNT_FILE | while IFS= read -r line; do
        ATTEMPTS=$(echo "$line" | awk '{print $1}')
        if [ $ATTEMPTS -gt $MAX_ATTEMPTS ]; then
                echo -e "Banning IP \c"
                IP="$(echo $line | awk '{print $2}')"
                echo $IP
                ban_ip $IP
        fi
done

#echo -e "\n*****READING FILE /etc/hosts.deny*****"
#cat /etc/hosts.deny