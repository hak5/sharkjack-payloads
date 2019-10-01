#!/bin/bash
#
# Title:        SSH IP Blinker
# Author:       Hak5Darren
# Version:      1.0
#
# Description:	This payload makes it easier to develop payloads which require Internet access.
# This is useful for installing packages via opkg, or testing payloads in development.
#
# It enables the SSH server, attempts to get an IP address from DHCP (Attack Mode default)
# then blinks the last octet of the IP address. Perfect for most /24 (255.255.255.0) home networks.
#
# Example: Plug the Shark Jack into your home network, wait ~45 seconds and it will blink cyan 
# four times, pause, then blink twice. This indicates that the last octet of its IP address is
# .42 - so if your home LAN is 192.168.1.0, then your Shark Jack should be found at 192.168.1.42
#
# Magenta...........Setup
# Red Slow Blink....Failed to obtain IP address
# Cyan Fast Blinks..Last octet of IPv4 address

LED SETUP
/etc/init.d/sshd start
sleep 10
LASTOCTET=$(ifconfig eth0 | grep "inet addr" | awk {'print $2'} | awk -F. {'print $4'})
LED OFF
LO1=${LASTOCTET:0:1}
LO2=${LASTOCTET:1:2}
LO3=${LASTOCTET:2:3}

while true; do

if [ -z "$LO1" ]
then
	LED FAIL
	exit 
else
	sleep 1
	i=0
	while [ $i -lt $LO1 ]
	do
		LED C SOLID; sleep 0.05
		LED OFF; sleep 0.125
		i=$(( $i + 1 ))
	done 
fi

if [ -z "$LO2" ]
then
	sleep 1
else
        sleep 1
        i=0                     
        while [ $i -lt $LO2 ]
        do                            
                LED C SOLID; sleep 0.05
                LED OFF; sleep 0.125
                i=$(( $i + 1 ))
        done
fi

if [ -z "$LO3" ]
then
	sleep 1
else
        sleep 1
        i=0                     
        while [ $i -lt $LO3 ]
        do                            
                LED C SOLID; sleep 0.05
                LED OFF; sleep 0.125
                i=$(( $i + 1 ))
        done
fi

sleep 2

done
