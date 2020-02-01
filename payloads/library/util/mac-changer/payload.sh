#!/bin/bash
#
# Title:        MAC Changer
# Author:       Dan Goodman
# Version:      1.0
#
# Description:	This payload changes the MAC address of the shark jack, then tests
# to see if it has internet access. The MAC address is, by default, randomized at boot.
#
# LED SETUP (Magenta)... Setting NETMODE to DHCP_CLIENT
# LED Blue... Changing MAC Address
# LED Cyan... Successfully changed MAC Address
# LED Red... No IP address from DHCP yet
# LED Yellow... Obtained IP address from DHCP, waiting on Internet access
# LED Green... Confirmed access to Internet

PUBLIC_TEST_URL="http://www.example.com"
C2CONNECT

LED SETUP
# Set NETMODE to DHCP_CLIENT for Shark Jack v1.1.0+
NETMODE DHCP_CLIENT

LED B SOLID
# Change MAC address
ifconfig eth0 down
ifconfig eth0 hw ether 7c:dd:90:f3:9f:5d
ifconfig eth0 up
LED C SOLID

LED R SOLID
while ! ifconfig eth0 | grep "inet addr"; do sleep 1; done
LED Y SOLID
while ! wget $PUBLIC_TEST_URL -qO /dev/null; do sleep 1; done
LED G SOLID
