#!/bin/bash
#
# Title:         Jack Tester
# Author:        Hydrox
# Version:       1.0
#
# Boots and looks for an ip address to test if the port is active on the LAN.
#
# Magenta Solid............Setup
# Red Slow Blink...........Inactive Jack
# Green....................Active Jack
#

function find_subnet() {
  SUBNET=$(ip addr | grep -i eth0 | grep -i inet | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}[\/]{1}[0-9]{1,2}" | sed 's/\.[0-9]*\//\.0\//')
}

function run() {
  LED SETUP

  # Find IP address and subnet
  for i in {1..30}; do
    sleep 1 && find_subnet

    if [ ! -z "$SUBNET" ]; then
      break;
    fi
  done

  if [ -z "$SUBNET" ]; then
    LED FAIL
  else
    LED FINISH
  fi
}

# Run payload
run &
