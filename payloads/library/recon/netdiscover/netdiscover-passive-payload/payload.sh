#!/bin/bash
#
# Title:         Passive netdiscover Payload for Shark Jack V 1.1.0
# Author:        Charles BLANC ROLIN
# Version:       1.0
#
# Broadcast ARP with netdiscover using specified options. Saves each scan result
# to loot storage folder.
#
# Packages needed : coreutils, librt, timeout, libnet, netdiscover
#
# Packages downloads :
#
# https://downloads.openwrt.org/releases/18.06.5/packages/mipsel_24kc/packages/coreutils_8.23-4_mipsel_24kc.ipk
# https://downloads.openwrt.org/releases/18.06.5/targets/ramips/mt76x8/packages/librt_1.1.19-2_mipsel_24kc.ipk
# https://downloads.openwrt.org/releases/18.06.5/packages/mipsel_24kc/packages/coreutils-timeout_8.23-4_mipsel_24kc.ipk
# https://downloads.openwrt.org/releases/18.06.5/packages/mipsel_24kc/packages/libnet-1.2.x_1.2-rc3-4_mipsel_24kc.ipk
# https://downloads.openwrt.org/releases/18.06.5/packages/mipsel_24kc/packages/netdiscover_0.3-pre-beta7-1_mipsel_24kc.ipk
#
# To verify sha256 hashes :
# https://downloads.openwrt.org/releases/18.06.5/packages/mipsel_24kc/packages/Packages
# https://downloads.openwrt.org/releases/18.06.5/targets/ramips/mt76x8/packages/Packages
#
# Red ...........Setup
# Amber..........Scanning
# Green..........Finished
#
# See netdiscover -h for options. Default "-p -P -N" fast scan with infos only.


# Configure interface eth0 in passive mode

NETMODE TRANSPARENT

NETDISCOVER_OPTIONS="-p -P -N"
LOOT_DIR=/root/loot/netdiscover

# You can define passive network listening duration. 5 minutes by default.

TIME="300s"

# Setup

LED SETUP

# Create loot directory

mkdir -p $LOOT_DIR &> /dev/null

function finish() {

	LED CLEANUP

	# Grep netdiscover process and kill

	if ps | grep -q "[n]etdiscover"; then
		
		ps | grep netdiscover | grep -v grep | awk '{print $2}' | xargs kill -9		
		finish

	else

	LED FINISH
	sleep 1

	# Halt system
	halt

	fi
}


function run() {

	LED ATTACK

	# Start scan

	timeout $TIME netdiscover $NETDISCOVER_OPTIONS > $LOOT_DIR/netdiscover-scan.txt

	finish

}


# Run payload

run &
