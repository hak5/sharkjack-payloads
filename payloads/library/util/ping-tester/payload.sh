#!/bin/bash
#
# Title:        Ping Tester
# Author:       Hak5Darren
# Version:      1.0
#
# Description:	This payload tests to see if the Shark Jack can ping
# a specified resource.
#
# LED SETUP (Magenta)... Obtaining IP address from DHCP
# LED FAIL (Red blink)... Unable to ping specified resource
# LED FINISH (Green blink to solid)... Successfully pinged resource

RESOURCE_TO_PING="192.168.86.27"

LED SETUP
while ! ifconfig eth0 | grep "inet addr"; do sleep 1; done
sleep 2
ping -c1 $RESOURCE_TO_PING && LED FINISH || LED FAIL