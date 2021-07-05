# Backup and Restore shell scripts for Shark Jack

Author: Robert Coemans

## Revision history

| Version | Date       | Author         | Changes                                                    |
| ------- | ---------- | -------------- | ---------------------------------------------------------- |
| 1.0     | 2020-08-20 | Robert Coemans | Initial version of the file.                               |

## Description

Being tired of having to re-image your Shark Jack and going through the hassle of backing up and restoring the device? These shell scripts will help you to backup and restore all important data on your Shark Jack.

The scripts has been created in a modular fashion which allows easy extending the scripts with new functions. The backup script (`backup.sh`) incorporates logic to determine already existing backup folders and create a new (unique) backup folder every time the script is executed.

## backup.sh

This section describes the `backup.sh` shell script.

### Use

1. Execute the script with: `bash ./backup.sh`

### Toggles

Toggle                       | Description                                                                      | Values
---------------------------- | -------------------------------------------------------------------------------- | ---
NOTIFY_PUSHOVER              | Send start/stop notifications to [Pushover](https://pushover.net/)               | true/false
START_CLOUD_C2_CLIENT        | Have script start Cloud C2 client in case Cloud C2 client is not yet started     | true/false
EXFIL_TO_CLOUD_C2            | Exfiltrate backup zip file and log file to Cloud C2                              | true/false
EXFIL_TO_SCP                 | Exfiltrate backup zip file and log file to external host using `scp`             | true/false

### Variables

Variable                     | Description                                                                      | Values
---------------------------- | -------------------------------------------------------------------------------- | ---
BACKUP_DIR_ROOT              | Folder on Shark Jack to store backup zip files and log files                     | {folder e.g. `/root/backup`}
BACKUP_FOLDERS               | Array containing folders to be backed up                                         | {array e.g. `( "/root/payload" "/root/loot" "/usr/share/arp-scan" )`}
BACKUP_FILES                 | Array containing files to be backed up                                           | {array e.g. `( "/etc/device.config" )`}
BACKUP_DESTINATION_USER      | Username for remote host for SCP exfiltration                                    | {username e.g. `root`}
BACKUP_DESTINATION_HOST      | Hostname or IP address for remote host for SCP exfiltration                      | {hostname/ip e.g. `192.168.10.1`}
BACKUP_DESTINATION_DIR_ROOT  | Folder on remote host for storing back zip file and log file                     | {folder e.g. `/root/downloads/backup`}
PUSHOVER_API_POST_URL        | Pushover post API url                                                            | https://api.pushover.net/1/messages.json
PUSHOVER_APPLICATION_TOKEN   | Pushover application token                                                       | {your-application-token}
PUSHOVER_USER_TOKEN          | Pushover user token                                                              | {your-user-token}
PUSHOVER_PRIORITY            | Pushover priority                                                                | -2 no notification/alert, -1 send as a quiet notification, 1 high-priority and bypass the user's quiet hours
PUSHOVER_DEVICE              | Pushover device, multiple devices may be separated by a comma                    | {your-device}

### Dependencies

This script depends on the following packages:

- curl
- zip

### Good to know

- Generate a ssh key (`ssh-keygen`) on the destination host and copy it (`~/.ssh/id_rsa_pub`) to the SharkJack (`~/.ssh/authorized/keys`) in order to bypass password for exfiltration to external host using `scp`!

### Status LED's

Color/Pattern | Meaning
------------- | ---
Setting up    | Magenta solid [LED SETUP]
Backing up    | Yellow single blink [LED ATTACK]
Finishing up  | Yellow double blink [LED STAGE2]
Finished      | Green very fast blinking followed by solid [LED FINISH]

## restore.sh

This section describes the `restore.sh` shell script.

### Use

1. Copy a backup created with `backup.sh` to the Shark Jack with: `scp backup.zip root@172.16.24.1:/destination/folder/` example: `scp 1-20200101-SharkJack-backup.zip root@172.16.24.1:/tmp/`
1. Execute the script with: `bash ./restore.sh /path/to/backup.zip` example: `bash ./restore.sh /tmp/1-20200101-SharkJack-backup.zip`

### Toggles

Toggle                       | Description                                                                      | Values
---------------------------- | -------------------------------------------------------------------------------- | ---
NOTIFY_PUSHOVER              | Send start/stop notifications to [Pushover](https://pushover.net/)               | true/false
START_CLOUD_C2_CLIENT        | Have script start Cloud C2 client in case Cloud C2 client is not yet started     | true/false
INSTALL_PACKAGES             | Have script install packages defined in variable `OPKG_PACKAGES_TO_INSTALL`      | true/false
RESTORE_ONLY_NEWER_FILES     | Skip newer files on restore destination                                          | true/false
EXFIL_TO_CLOUD_C2            | Exfiltrate backup zip file and log file to Cloud C2                              | true/false
EXFIL_TO_SCP                 | Exfiltrate backup zip file and log file to external host using `scp`             | true/false

### Variables

Variable                     | Description                                                                      | Values
---------------------------- | -------------------------------------------------------------------------------- | ---
RESTORE_DIR_ROOT             | Temporary folder on Shark Jack for unzipping back zip file and storing log file  | {folder e.g. `/root/restore`}
RESTORE_DESTINATION_USER     | Username for remote host for SCP exfiltration                                    | {username e.g. `root`}
RESTORE_DESTINATION_HOST     | Hostname or IP address for remote host for SCP exfiltration                      | {hostname/ip e.g. `192.168.10.1`}
RESTORE_DESTINATION_DIR_ROOT | Folder on remote host for storing log file                                       | {folder e.g. `/root/downloads/backup`}
PUSHOVER_API_POST_URL        | Pushover post API url                                                            | `https://api.pushover.net/1/messages.json`
PUSHOVER_APPLICATION_TOKEN   | Pushover application token                                                       | {your-application-token}
PUSHOVER_USER_TOKEN          | Pushover user token                                                              | {your-user-token}
PUSHOVER_PRIORITY            | Pushover priority                                                                | `-2` no notification/alert, `-1` send as a quiet notification, `1` high-priority and bypass the user's quiet hours
PUSHOVER_DEVICE              | Pushover device, multiple devices may be separated by a comma                    | {your-device}

### Dependencies

This script depends on the following packages:

- curl
- unzip

### Good to know

- Be careful with variable `RESTORE_DIR_ROOT`, this folder and all its contents including subfolders will be deleted during restore actions!
- Generate a ssh key (`ssh-keygen`) on the destination host and copy it (`~/.ssh/id_rsa_pub`) to the SharkJack (`~/.ssh/authorized/keys`) in order to bypass password for exfiltration to external host using `scp`!

### Status LED's

Color/Pattern | Meaning
------------- | ---
Setting up    | Magenta solid [LED SETUP]
Restoring     | Yellow single blink [LED ATTACK]
Finishing up  | Yellow double blink [LED STAGE2]
Finished      | Green very fast blinking followed by solid [LED FINISH]

## Discussion

[Hak5 Forum Thread](https://forums.hak5.org/topic/52883-payload-backup-and-restore-shell-scripts-for-shark-jack/)
