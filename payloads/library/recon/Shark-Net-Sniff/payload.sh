#!/bin/bash
#
# Title: Wireshark PCAP Capture & Examine
# Author: BuffBaby253
# Version: 1.1
# 
# Description: uses tcpdump to capture network traffic for 1 minute and saves into pcap
# into loot storage folder for further analysis in Wireshark
#
# Note: If you want to extend the time, change the amount of seconds in line 38
#
# LED SETUP   making loot directory and waiting for an ip address from DHCP
# LED ATTACK   capturing packets
# LED FINISH   the Shark Jack is finished and you can now download saved pcaps to open in Wireshark

LOOT_DIR=/root/loot/pcaps
INTERFACE="eth0"
seconds=60


# preparing for capture

LED SETUP 

# setting up loot directory
mkdir -p $LOOT_DIR
COUNT=$(($(ls -l $LOOT_DIR/*.txt | wc -l)+1))

# waiting for ip address

NETMODE DHCP_CLIENT
while [ -z "$IPADDR" ]; do sleep 1 && IPADDR=$(ifconfig eth0 | grep "inet addr"); done

LED ATTACK

# using tcpdump to capture network traffic and save to loot directory
tcpdump -i $INTERFACE -w $LOOT_DIR/net-traffic_$COUNT.txt &

# sleep command will let it run for amount of seconds selected
sleep $seconds

# end capture
killall tcpdump

# the work is done and you can unplug
LED FINISH
