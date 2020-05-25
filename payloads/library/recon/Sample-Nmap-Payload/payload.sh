#!/bin/bash
#
# Title:         Sample Nmap Payload for Shark Jack
# Author:        Hak5
# Version:       1.0
#
# Scans target subnet with Nmap using specified options. Saves each scan result
# to loot storage folder.
#
# Red ...........Setup
# Amber..........Scanning
# Green..........Finished
#
# See nmap --help for options. Default "-sP" ping scans the address space for
# fast host discovery.

NMAP_OPTIONS="-sP"
LOOT_DIR=/root/loot/nmap
SCAN_DIR=/etc/shark/nmap


function finish() {
	LED CLEANUP
	# Kill Nmap
	wait $1
	kill $1 &> /dev/null

	# Sync filesystem
	rm $SCAN_FILE
	echo $SCAN_M > $SCAN_FILE
	sync
	sleep 1

	LED FINISH
	sleep 1

	# Halt system
	halt
}

function setup() {
	LED SETUP
	# Create loot directory
	mkdir -p $LOOT_DIR &> /dev/null
	
	# Set NETMODE to DHCP_CLIENT for Shark Jack v1.1.0+
	NETMODE DHCP_CLIENT
	# Wait for an IP address to be obtained
	while ! ifconfig eth0 | grep "inet addr"; do sleep 1; done

	# Create tmp scan directory
	mkdir -p $SCAN_DIR &> /dev/null

	# Create tmp scan file if it doesn't exist
	SCAN_FILE=$SCAN_DIR/scan-count
	if [ ! -f $SCAN_FILE ]; then
		touch $SCAN_FILE && echo 0 > $SCAN_FILE
	fi

	# Find IP address and subnet
	while [ -z "$SUBNET" ]; do
		sleep 1 && find_subnet
	done
}

function find_subnet() {
	SUBNET=$(ip addr | grep -i eth0 | grep -i inet | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}[\/]{1}[0-9]{1,2}" | sed 's/\.[0-9]*\//\.0\//')
}

function run() {
	# Run setup
	setup

	SCAN_N=$(cat $SCAN_FILE)
	SCAN_M=$(( $SCAN_N + 1 ))

	LED ATTACK
	# Start scan
	nmap $NMAP_OPTIONS $SUBNET -oN $LOOT_DIR/nmap-scan_$SCAN_M.txt &>/dev/null &
	tpid=$!

	finish $tpid
}


# Run payload
run &
