#!/bin/bash

#Count number of login attempts from different hosts

TMP_FILE="/tmp/ip/ipss.txt"
COUNT_FILE="/tmp/ip/ipsc.txt"

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
