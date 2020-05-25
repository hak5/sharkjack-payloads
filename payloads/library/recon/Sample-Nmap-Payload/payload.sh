#!/bin/bash
#
# Title:         Sample Nmap Payload for Shark Jack
# Author:        Hak5
# Version:       1.1
#
# Scans target subnet with Nmap using specified options. Saves each scan result
# to loot storage folder.
#
# LED SETUP ... Obtaining IP address from DHCP
# LED ATTACK ... Scanning
# LED FINISH ... Scan Complete
#
# See nmap --help for options. Default "-sP" ping scans the address space for
# fast host discovery.

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
LED FINISH                                                                          
sleep 2 && halt
