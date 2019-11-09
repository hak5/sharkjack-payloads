#!/bin/bash
#
# Title:        Package Installer
# Author:       Hak5Darren
# Version:      1.0
#
# Description:	This payload will install the specified package using opkg.
# Use this to provision your Shark Jack for payloads with dependencies.
# Set PACKAGE_TO_INSTALL to the package you wish to install - for example
# PACKAGE_TO_INSTALL="nano" will install the best text editor on Earth ;)
# For a list of available packages, set LIST_PACKAGES to 1 - the results
# will be saved to a log file in the loot directory. Requires Internet.
#
# LED SETUP (Magenta)... Setting logs and waiting for IP address from DHCP
# LED FAIL (Red Slow Blink)... Failed to update opkg or install package
# LED SPECIAL (Cyan Blink)... Saving package list to log file
# LED FINISH (Green Fast Blink to Solid)... Package install or list successful

PACKAGE_TO_INSTALL="nano"
LIST_PACKAGES=0                     
LOG_DIR=/root/loot/package-installer
                                  
function FAIL() { LED FAIL; exit; }     
function SUCCESS() { LED FINISH; exit; }
         
LED SETUP
# Set NETMODE to DHCP_CLIENT for Shark Jack v1.1.0+
NETMODE DHCP_CLIENT
# Make log file
mkdir -p $LOG_DIR
LOG_FILE="package-installer_$(find $LOG_DIR -type f | wc -l).log"
DISK_SPACE_BEFORE=$(df -h | grep overlayfs | awk {'print $4'})
LOG="$LOG_DIR/$LOG_FILE"

# Wait until Shark Jack has an IP address                                             
while [ -z "$IPADDR" ]; do sleep 1 && IPADDR=$(ifconfig eth0 | grep "inet addr"); done
                                                                                      
LED ATTACK           
# Update package list                                
echo -e "#\n#\n# Updating Package List\n#\n#" >> $LOG
opkg update >> $LOG 2>&1 || FAIL                     
                                                     
if [ "$LIST_PACKAGES" = "1" ]; then
    LED SPECIAL                                             
    opkg list --size >> $LOG 2>&1 || FAIL && SUCCESS                   
fi                                                                     
                                                                       
# Install package                                                      
echo -e "#\n#\n# Installing Package: $PACKAGE_TO_INSTALL\n#\n#" >> $LOG
opkg install $PACKAGE_TO_INSTALL >> $LOG 2>&1 || FAIL                         
                                                                              
# Finalizing log file                                                         
echo -e "#\n#\n# Payload Complete \n#\n#\n\                                   
# Disk space free before: $DISK_SPACE_BEFORE\n\                               
# Disk space free after: $(df -h | grep overlayfs | awk {'print $4'})" >> $LOG
                                                                              
SUCCESS
