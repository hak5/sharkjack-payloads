#!/bin/bash
#
# Title:        Internet Access Tester
# Author:       Hak5Darren
# Version:      1.0
#
# Description:	This payload tests the port to see if the Shark Jack can
# obtain an IP address from DHCP, and if it can access the Internet by
# testing a specified HTTP URL.
#
# LED SETUP (Magenta)... Setting NETMODE to DHCP_CLIENT
# LED Red... No IP address from DHCP yet
# LED Yellow... Obtained IP address from DHCP, waiting on Internet access
# LED Green... Confirmed access to Internet

PUBLIC_TEST_URL="http://www.example.com"

LED SETUP
# Set NETMODE to DHCP_CLIENT for Shark Jack v1.1.0+
NETMODE DHCP_CLIENT

LED R SOLID
while ! ifconfig eth0 | grep "inet addr"; do sleep 1; done
LED Y SOLID
while ! wget $PUBLIC_TEST_URL -qO /dev/null; do sleep 1; done
LED G SOLID
