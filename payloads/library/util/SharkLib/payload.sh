#!/bin/bash
#
# Title:         SharkLib
# Author:        REDD of Private-Locker
# Version:       1.3
#
# This Script is to be ran on the Hak5 SharkJack itself. This Script
# makes switching between local stored payloads quick and simple.
#

VERS=1.3
LIB_DIR="/root/payload/sharklib"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
START_DIR="$DIR"
INSTALL_DIR="/usr/sbin"
EXEC_FILE="sharklib"
PAYLOAD_DIR="/root/payload"
PAYLOAD_FILE="$PAYLOAD_DIR/payload.sh"

function install_sharklib() {
    if [[ "$DIR" != $INSTALL_DIR ]]; then
	    if [ ! -f "$INSTALL_DIR/$EXEC_FILE" ]; then
		    printf " -> Installing SharkLib into System for Easy Access.\n"
		    sleep 1;
		    cp -rf $0 $INSTALL_DIR/$EXEC_FILE
		    printf " -> Fixing Permissions of $EXEC_FILE in $INSTALL_DIR.\n"
		    sleep 1;
		    chmod +x $INSTALL_DIR/$EXEC_FILE
	    fi
    fi
}

function view_payload() {
    printf "\n";
    cat "$PAYLOAD_FILE";
    printf "\n";
    read -n 1 -s -r -p "Press any key to return to Menu..";
    sharklib_menu;
}

function remove_sharklib() {
	if [ -f "$INSTALL_DIR/$EXEC_FILE" ]; then
		printf "\n"
		printf "Removing SharkLib from local system.\n"
		rm -rf "$INSTALL_DIR/$EXEC_FILE";
		printf "Removing SharkLib Payload Library.\n"
		rm -rf "$LIB_DIR";
		printf "SharkLib has been fully removed.\n\n"
	fi
}

function free_space() {
	FREE_MEM="$(df -h $PWD | awk '/[0-9]%/{print $(NF-2)}')"
}


function header() {
free_space;
printf "\n"
printf "O========================================O\n"
printf "|   SharkLib - SharkJack Quick Payload   |\n"
printf "|                    Library             |\n"
printf "O=O====================================O=O\n"
printf "  |   %-29s    |\n" "$SHARKLIB_TITLE"
printf "  O====================================O\n"
printf "    | Free Space: %-6s   Vers: %-3s | \n" "$FREE_MEM" "$VERS"
printf "    O================================O \n"
printf "         -Huge Thanks goes to Hak5!    \n"
printf "\n"
}

function backup_payload() {
	clear;
	SHARKLIB_TITLE="        Backup Payloads"
	header;
	if [ -f "$PAYLOAD_FILE" ]; then
		printf "\n"
		printf "    1. Backup current payload to SharkLib\n"
		printf "\n"
		printf "    2. Return to Previous Menu.\n"
		printf "\n"
		printf "   Select a Menu Item by # and press ENTER: "
		read BACKUP_INPUT
		printf "\n"
		if [ "$BACKUP_INPUT" = "1" ]; then
			printf "   What would you want to call this Payload?: "
			read BACKUP_INPUT_1
			if [[ "$BACKUP_INPUT_1" != "" ]]; then
				if [ ! -d "$LIB_DIR/$BACKUP_INPUT_1" ]; then
					mkdir -p "$LIB_DIR/$BACKUP_INPUT_1"
					cp -rf "$PAYLOAD_FILE" "$LIB_DIR/$BACKUP_INPUT_1/payload.sh"
					printf "   Created Payload directory named $BACKUP_INPUT_1\n"
					sleep 2;
					sharklib_menu;
				else
					printf "   Removing Old Copy and using New Copy of $BACKUP_INPUT_1\n"
					rm -rf "$LIB_DIR/$BACKUP_INPUT_1"
					mkdir -p "$LIB_DIR/$BACKUP_INPUT_1"
					cp -rf "$PAYLOAD_FILE" "$LIB_DIR/$BACKUP_INPUT_1/payload.sh"
					sleep 2;
					sharklib_menu;
				fi
			else
				if [ ! -d "$LIB_DIR/Payload" ]; then
					printf "   Backing up Payload into Default Payload directory..\n"
					mkdir -p "$LIB_DIR/Payload"
					cp -rf "$PAYLOAD_FILE" "$LIB_DIR/Payload/payload.sh"
					sleep 2;
					sharklib_menu;
				else
                                        printf "   Removing Old Copy and using New Copy of $LIB_DIR/Payload\n"
                                        rm -rf "$LIB_DIR/Payload"
                                        mkdir -p "$LIB_DIR/Payload"
					cp -rf "$PAYLOAD_FILE" "$LIB_DIR/Payload/payload.sh"
					sleep 2;
					sharklib_menu;
				fi
			fi
		elif [ "$BACKUP_INPUT" = "2" ]; then
			sharklib_menu;
		else
			backup_payload;
		fi
	else
		printf "   No Payload in $PAYLOAD_DIR.\n"
	fi
}

function delete_payload() {
	DELETE_INPUT=NULL
	clear;
	SHARKLIB_TITLE="        Delete Payloads"
	header;
	cd "$LIB_DIR"
	DIR_CNT="NULL"
	DIR_CNT=$(ls "$LIB_DIR" | grep -v total | wc -l)
	declare -a DIRS
	i=1
	for d in */; do
		DIRS[i++]="${d%/}"
	done
	if [ "$DIR_CNT" -lt "1" ]; then
                printf "   There are no Payloads to Delete. \n\n"
		printf "   Returning to Previous Menu.\n"
                sleep 2;
                sharklib_menu;
	fi
	printf "   There are ${#DIRS[@]} Payloads in SharkLib:\n"
	for((i=1;i<=${#DIRS[@]};i++)); do
		printf "    %2d. %-20s\n" "$i" "${DIRS[i]}"
	done
        PAYLOAD_TOTAL=${#DIRS[@]}
        PLUS_QUIT=$((PAYLOAD_TOTAL+1))
	printf "\n"
	printf "    %2d. %-20s\n" "$PLUS_QUIT" "Return to Previous Menu."
	printf "\n"
	printf "   Please choose a Payload by Number: "
	read DELETE_INPUT
	printf "\n"
	if [[ "$DELETE_INPUT" == "$PLUS_QUIT" ]]; then
		printf "   Returning to Previous Menu.\n"
		sleep 2;
		sharklib_menu;
        elif [[ "$DELETE_INPUT" == "" ]]; then
                printf "   Please Input a choice.\n"
				sleep 2;
                delete_payload;
		elif ! [[ "$DELETE_INPUT" =~ ^[0-9]+$ ]]; then
                printf "   Please Input a choice.\n"
                sleep 2;
                delete_payload;
        elif [[ "$DELETE_INPUT" == "0" ]]; then
                printf "   Please Input a choice.\n"
                sleep 2;
                delete_payload;
        elif [[ "$DELETE_INPUT" -gt "$PLUS_QUIT" ]]; then
		printf "   Please Input a choice.\n"
		sleep 2;
		delete_payload;
	elif [[ "$DELETE_INPUT" -le "$PLUS_QUIT" ]]; then
		printf "   Deleting payload ${DIRS[$DELETE_INPUT]} from SharkJack. \n"
		rm -rf "$LIB_DIR/${DIRS[$DELETE_INPUT]}"
		cd "$START_DIR"
		sleep 2;
		sharklib_menu;
	else
		printf "   Wrong Choice, going back to Previous Menu.\n"
		cd "$START_DIR"
		sleep 2;
		sharklib_menu;
	fi
}


function restore_payload() {
	LOAD_INPUT=NULL
	clear;
	SHARKLIB_TITLE="        Restore Payloads"
	header;
	cd "$LIB_DIR"
        DIR_CNT=$(ls "$LIB_DIR" | grep -v total | wc -l)
	declare -a DIRS
	i=1
	for d in */; do
		DIRS[i++]="${d%/}"
	done
        if [ "$DIR_CNT" -lt "1" ]; then
                printf "   There are no Payloads to Restore. \n\n"
		printf "   Returning to Previous Menu.\n"
		sleep 2;
		sharklib_menu;
        fi
	printf "   There are ${#DIRS[@]} Payloads in SharkLib:\n"
	for((i=1;i<=${#DIRS[@]};i++)); do
		printf "    %2d. %-20s\n" "$i" "${DIRS[i]}"
	done
        PAYLOAD_TOTAL=${#DIRS[@]}
        PLUS_QUIT=$((PAYLOAD_TOTAL+1))
	printf "\n"
	printf "    %2d. %-20s\n" "$PLUS_QUIT" "Return to Previous Menu."
	printf "\n"
	printf "   Please choose a Payload by Number: "
	read LOAD_INPUT
	printf "\n"
	if [[ "$LOAD_INPUT" == "$PLUS_QUIT" ]]; then
		printf "   Returning to Previous Menu.\n"
		sleep 2;
		sharklib_menu;
        elif [[ "$LOAD_INPUT" == "" ]]; then
                printf "   Please Input a choice.\n"
		sleep 2;
                restore_payload;
		elif ! [[ "$LOAD_INPUT" =~ ^[0-9]+$ ]]; then
                printf "   Please Input a choice.\n"
                sleep 2;
                restore_payload;
        elif [[ "$LOAD_INPUT" == "0" ]]; then
                printf "   Please Input a choice.\n"
                sleep 2;
                restore_payload;
        elif [[ "$LOAD_INPUT" -gt "$PLUS_QUIT" ]]; then
                printf "   Please Input a choice.\n"
                sleep 2;
                restore_payload;
	elif [[ "$LOAD_INPUT" -le "$PLUS_QUIT" ]]; then
		printf "   Loading payload ${DIRS[$LOAD_INPUT]} to SharkJack. \n"
		cp -rf "$LIB_DIR/${DIRS[$LOAD_INPUT]}/payload.sh" "$PAYLOAD_FILE"
		cd "$START_DIR"
		sleep 2;
		sharklib_menu;
	else
		printf "   Wrong Choice, going back to Previous Menu.\n"
		cd "$START_DIR"
		sleep 2;
		sharklib_menu;
	fi
}
function cleanup_ctrl {
	echo -en "\n -> Caught SIGINT! \n"
	printf " -> Cleaning up and Exiting..\n\n"
	sync
	sleep 1;
	exit $?
}
function exit_sharklib() {
	printf " -> Cleaning up and Exiting..\n\n"
	sync
	sleep 1;
	exit 0;
}

function sharklib_menu() {
	clear;
	trap cleanup_ctrl SIGINT
	trap cleanup_ctrl SIGTERM
	MENU_INPUT=NULL
	if [ ! -d "$LIB_DIR" ]; then
		printf " -> Creating SharkLib Payload Library directory.\n"
		mkdir -p "$LIB_DIR"
	fi
	cd "$LIB_DIR"
	SHARKLIB_TITLE="            By REDD"
	header;
        printf "    1. Backup Payload to SharkLib\n"
	printf "    2. Restore Payload from SharkLib\n"
	printf "    3. Delete Payload from SharkLib\n"
	printf "\n"
	printf "    4. View Current Payload on SharkJack\n"
	printf "\n"
	printf "    5. Exit\n"
	printf "\n"
	printf "   Select a Menu Item by # and press ENTER: "
	read MENU_INPUT
	printf "\n"
    if ! [[ "$MENU_INPUT" =~ ^[0-9]+$ ]]; then
            sharklib_menu;
        elif [[ "$MENU_INPUT" = "0" ]]; then
            sharklib_menu;
		elif [[ "$MENU_INPUT" = "1" ]]; then
            backup_payload;
		elif [[ "$MENU_INPUT" = "2" ]]; then
            restore_payload;
        elif [[ "$MENU_INPUT" = "3" ]]; then
            delete_payload;
        elif [[ "$MENU_INPUT" = "4" ]]; then
            view_payload;
		elif [[ "$MENU_INPUT" = "5" ]]; then
            exit_sharklib;
		elif [[ "$MENU_INPUT" -ge "6" ]]; then
			sharklib_menu;
		elif [[ "$MENU_INPUT" == "" ]]; then
			sharklib_menu;
		else
			sharklib_menu;
	fi
}
if [ "$1" == "--install" ]; then
    install_sharklib;
    exit 0;
elif [ "$1" == "--remove" ]; then
	remove_sharklib;
else
    install_sharklib;
	sharklib_menu;
fi
