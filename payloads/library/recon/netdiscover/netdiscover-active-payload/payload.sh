#!/bin/bash
#
# Title:         Active netdiscover Payload for Shark Jack V 1.1.0
# Author:        Charles BLANC ROLIN
# Version:       1.0
#
# Broadcast ARP with netdiscover using specified options. Saves each scan result
# to loot storage folder.
#
# Packages needed : libnet, netdiscover
#
# Packages downloads :
#
# https://downloads.openwrt.org/releases/18.06.5/packages/mipsel_24kc/packages/libnet-1.2.x_1.2-rc3-4_mipsel_24kc.ipk
# https://downloads.openwrt.org/releases/18.06.5/packages/mipsel_24kc/packages/netdiscover_0.3-pre-beta7-1_mipsel_24kc.ipk
#
# To verify sha256 hashes : https://downloads.openwrt.org/releases/18.06.5/packages/mipsel_24kc/packages/Packages
#
# Red ...........Setup
# Amber..........Scanning
# Green..........Finished
#
# See netdiscover -h for options. Default "-S -P -N" fast scan with infos only.

# Configure interface eth0 in passive mode

NETMODE TRANSPARENT

NETDISCOVER_OPTIONS="-S -P -N"
LOOT_DIR=/root/loot/netdiscover
SCAN_DIR=/etc/shark/netdiscover

function finish() {

	LED CLEANUP

	# Grep netdiscover process

	if ps | grep -q "[n]etdiscover"; then
		
		finish

	else

	# Sync filesystem
	echo $SCAN_M > $SCAN_FILE
	sync
	sleep 1

	LED FINISH
	sleep 1

	# Halt system
	halt

	fi
}

function setup() {

	LED SETUP

	# Create loot directory

	mkdir -p $LOOT_DIR &> /dev/null

	# Create tmp scan directory

	mkdir -p $SCAN_DIR &> /dev/null

	# Create tmp scan file if it doesn't exist

	SCAN_FILE=$SCAN_DIR/scan-count
	if [ ! -f $SCAN_FILE ]; then
		touch $SCAN_FILE && echo 0 > $SCAN_FILE
	fi
}

function run() {

	# Run setup

	setup

	SCAN_N=$(cat $SCAN_FILE)
	SCAN_M=$(( $SCAN_N + 1 ))

	LED ATTACK

	# Start scan

	netdiscover $NETDISCOVER_OPTIONS > $LOOT_DIR/netdiscover-scan_$SCAN_M.txt

	finish

}


# Run payload

run &
