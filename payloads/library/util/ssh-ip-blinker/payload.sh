#!/bin/bash
#
# Title:        SSH IP Blinker
# Author:       Hak5Darren
# Version:      1.1
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
# If one of the octets is zero this will be represented as solid for 1 second.
#
# Magenta...........Setup
# Red Slow Blink....Failed to obtain IP address
# Cyan Fast Blink...A non-zero digit of last octet
# Cyan Solid........A zero digit of last octet

LED SETUP
# Set NETMODE to DHCP_CLIENT for Shark Jack v1.1.0+
NETMODE DHCP_CLIENT
# Wait for an IP address to be obtained
while ! ifconfig eth0 | grep "inet addr"; do sleep 1; done
# Start SSH server
/etc/init.d/sshd start
sleep 10
LASTOCTET=$(ifconfig eth0 | grep "inet addr" | awk {'print $2'} | awk -F. {'print $4'})
LED OFF

if [ -z "$LASTOCTET" ]; then
	LED FAIL
	exit
fi

while true; do
	for (( i = 0; i < ${#LASTOCTET}; i++ )); do
		DIGIT=${LASTOCTET:$i:1}

		if [ $DIGIT = "0" ]; then
			LED C SOLID; sleep 1
			LED OFF; sleep 0.125
		else
			for (( j = 0; j < $DIGIT; j++ )); do
				LED C SOLID; sleep 0.05
				LED OFF; sleep 0.125
			done
		fi

		sleep 1
	done

	sleep 2
done
