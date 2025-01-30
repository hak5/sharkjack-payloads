# Network reconnaissance payload for Shark Jack

Author: Robert Coemans

## Revision history

| Version | Date       | Author         | Changes                                                    |
| ------- | ---------- | -------------- | ---------------------------------------------------------- |
| 1.0     | 2020-08-19 | Robert Coemans | Initial version of the file.                               |
| 1.1     | 2020-08-21 | Robert Coemans | Added Stealth Mode and fixed LLDP attack function.         |

## Description

Swiss knife network reconnaissance payload with options for loot capturing (e.g. DIG, NMAP, IFCONFIG, ARP-SCAN, LLDP), notification (e.g. Homey, Pushover (the best push notfications service!), Slack), exfiltration (e.g. Cloud C2, Pastebin, Slack) and led blinking for IP address. Payload is based on various sample payloads from HAK5, MonsieurMarc, Topknot and others.

The script has been created in a modular fashion which allows easy extending the script with new functions (e.g. recon, notification or exfiltration functions). The script furthermore incorporates logic to determine already existing loot folders and create a new (unique) loot folder every time the script is executed.

## payload.sh

This section explains the `payload.sh` shell script.

### Use

1. Copy to `/root/payload` folder with the name `payload.sh`: `/root/payload/payload.sh`

### Toggles

Toggle                               | Description                                                                                         | Values
------------------------------------ | --------------------------------------------------------------------------------------------------- | ---
STEALTH_MODE                         | Turn LED off during attack                                                                          | true/false
CHANGE_HOSTNAME                      | Use an alternative hostname by using the variable `HOSTNAME`                                        | true/false
CHANGE_MAC_ADDRESS                   | Use an alternative mac address by using the variable `MAC_ADDRESS`                                  | true/false
LOOKUP_SUBNET                        | Lookup the subnet                                                                                   | true/false
COPY_BACK_DHCP_RETRIEVED_DNS_SERVERS | Copy back the automatically detected DHCP information e.g. DNS servers and domain                   | true/false
USE_CUSTOM_DNS_SERVER                | Use a manually specified DNS server                                                                 | true/false
START_SSH_SERVER                     | Start the Secure SHell server (not needed in case Cloud C2 is being used)                           | true/false
CHECK_DEFAULT_GATEWAY                | Lookup and test the default gateway                                                                 | true/false
CHECK_INTERNET_ACCESS                | Test Internet connectivity                                                                          | true/false
GET_EXTERNAL_IP_ADDRESS              | Get the external (public) IP address by using the service specified in the variable `PUBLIC_IP_URL` | true/false
NOTIFY_HOMEY                         | Send start/stop notifications to [Homey](https://homey.app)                                         | true/false
NOTIFY_PUSHOVER                      | Send start/stop notifications to [Pushover](https://pushover.net/)                                  | true/false
NOTIFY_SLACK                         | Send start/stop notifications to [Slack](https://slack.com)                                         | true/false
START_CLOUD_C2_CLIENT                | Have script start Cloud C2 client in case Cloud C2 client is not yet started                        | true/false
GRAB_IFCONFIG_LOOT                   | Grab loot around the ETH0 interface                                                                 | true/false
GRAB_TRACEROUTE_LOOT                 | Grab traceroute loot by using the host given in the variable `TRACEROUTE_HOST`                      | true/false
GRAB_DNS_INFORMATION_LOOT            | Grab Domain Name System information stored on the Shark Jack (see: `RESOLV.CONF` variables)         | true/false
GRAB_PUBLIC_IP_WHOIS_LOOT            | Grab public WHOIS loot for the external (public) IP address                                         | true/false
GRAB_LLDP_LOOT                       | Grab loot around interfaces and neighbours using the Link Layer Discovery Protocol                  | true/false
GRAP_ARP_SCAN_LOOT                   | Grab ARP (Address Resolution Protocol) loot including looking up of MAC addresses                   | true/false
GRAB_NMAP_LOOT                       | Grab NMAP (Network Mapper) loot                                                                     | true/false
GRAB_NMAP_INTERESTING_HOSTS_LOOT     | Grab NMAP (Network Mapper) loot for interesting files (more extensive NMAP lookup can be enforced)  | true/false
GRAB_DIG_LOOT                        | Grab DNS loot using DIG                                                                             | true/false
TRY_TO_GET_INTERNAL_DOMAINS          | Try to get the internal domains automatically (lookup `/tmp/resolv.conf.auto`)                      | true/false
EXFIL_TO_CLOUD_C2                    | Exfiltrate loot files and log file to Cloud C2                                                      | true/false
EXFIL_TO_PASTEBIN                    | Exfiltrate loot files and log file to Pastebin                                                      | true/false
EXFIL_TO_SLACK                       | Exfiltrate loot files and log file to Slack                                                         | true/false
BLINK_INTERNAL_IP_ADDRESS            | Blink the whole or part of the internal (private) IP address after the loot is in                   | true/false
HALT_SYSTEM_WHEN_DONE                | Halt the system in order to preserve resources and battery                                          | true/false

### Variables

Variable                       | Description                                                                      | Values
------------------------------ | -------------------------------------------------------------------------------- | ---
LOOT_DIR_ROOT                  | Folder on Shark Jack to store loot files and log files                           | {folder e.g. `/root/loot/network-recon`}
HOSTNAME                       | Custom hostname for the Shark Jack                                               | {e.g. `shark`}
MAC_ADDRESS                    | Custom MAC address for the Shark Jack                                            | {e.g. `4a:3f:6d:db:ba:d8`}
CUSTOM_NAME_SERVER             | Custom name server to be used by the Shark Jack                                  | {e.g. `192.168.10.1`}
RESOLV_CONF_FILE               | Path to `resolv.conf` file                                                       | {e.g. `/etc/resolv.conf`}
RESOLV_CONF_AUTO_FILE          | Path to `resolv.conf.auto` file                                                  | {e.g. `/tmp/resolv.conf.auto`}
RESOLV_CONF_TMP_FILE           | Path to `resolv.conf` temporary file                                             | {e.g. `/tmp/resolv.conf`}
INTERNET_TEST_HOST             | Host to be used to test Internet access                                          | {e.g. `http://www.google.com`}
PUBLIC_IP_URL                  | Host to be used to get the external (private) IP address                         | {e.g. `http://icanhazip.com`}
TRACEROUTE_HOST                | Host to execute the traceroute against                                           | {e.g. `8.8.8.8`}
INTERNAL_DOMAINS               | Manually set (internal) domain                                                   | {e.g. `mydomain.local`}
BANDWIDTH_FOR_ARP_SCAN         | Max. bandwith used by arp-scan                                                   | {e.g. `100000`]
NMAP_OPTIONS_ACTIVE_HOSTS      | NMAP options to be used for active hosts (NMAP quick scan)                       | {e.g. `--top-ports 20`}
INTERESTING_HOSTS_PATTERN      | String of interesting hosts to filter on                                         | {e.g. `Synology|QNAP`}
NMAP_OPTIONS_INTERESTING_HOSTS | NMAP options to be used for interesting hosts (NMAP elaborated scan)             | {e.g. `-v -sS -A -T4`}
HOMEY_WEBHOOK_URL              | WEbhook url for Homey                                                            | {e.g. `https://{your-homey-id}.connect.athom.com/api/manager/logic/webhook/{your-endpoint`}
PUSHOVER_API_POST_URL          | Pushover post API url                                                            | https://api.pushover.net/1/messages.json
PUSHOVER_APPLICATION_TOKEN     | Pushover application token                                                       | {your-application-token}
PUSHOVER_USER_TOKEN            | Pushover user token                                                              | {your-user-token}
PUSHOVER_PRIORITY              | Pushover priority                                                                | -2 no notification/alert, -1 send as a quiet notification, 1 high-priority and bypass the user's quiet hours
PUSHOVER_DEVICE                | Pushover device, multiple devices may be separated by a comma                    | {your-device}
PASTEBIN_API_LOGIN_URL         | Pastebin login API url                                                           | {e.g. `https://pastebin.com/api/api_login.php`}
PASTEBIN_API_POST_URL          | Pastebin post API url                                                            | {e.g. `https://pastebin.com/api/api_post.php`}
PASTEBIN_API_USER              | Pastebin username                                                                | {e.g. `{username}`}
PASTEBIN_API_PASSWORD          | Pastebin password                                                                | {e.g. `{password}`}
PASTEBIN_API_KEY               | Pastebin API key                                                                 | {e.g. `{your-api-key}`}
PASTEBIN_EXPIRE_DATE           | Pastebin 'pastes' expiration date                                                | N = Never, 10M = 10 Minutes, 1H = 1 Hour, 1D = 1 Day, 1W = 1 Week, 2W = 2 Weeks, 1M = 1 Month, 6M = 6 Months, 1Y = 1 Year
SLACK_API_POST_URL             | Slack post API url                                                               | {e.g. `https://slack.com/api/chat.postMessage`}
SLACK_API_UPLOAD_URL           | Slack upload API url                                                             | {e.g. `https://slack.com/api/files.upload`}
SLACK_OAUTH_TOKEN              | Slack OAuth token                                                                | {e.g. `{your-oauth-token}`}
SLACK_CHANNEL_ID               | Slack channel identifier                                                         | {e.g. `{your-channel-id}`}, use Slack web app to capture channel ID (last bit of URL)
SLACK_USER                     | Slack username which will publish the message                                    | {e.g. `{your-slack-user}`}

### Dependencies

This script depends on the following packages:

- curl
- lldpd
- bind-dig
- bind-host
- libustream-openssl

Not dependent on but good to have:

- nano

### Good to know

- For setting up Slack (exfiltration and notification) check this [tutorial](https://dev.to/c0d3b0t/upload-and-publish-a-file-on-slack-channel-with-bash-i2e)!
- ARP-SCAN is using files: `/usr/share/arp-scan/ieee-iab.txt`, `/usr/share/arp-scan/ieee-oui.txt` and `/usr/share/arp-scan/mac-vendor.txt` to retrieve vendors based on discovered MAC addresses!
- Uncomment sections in function **BLINK_INTERNAL_IP_ADDRESS** in case you want to blink other octets as well!
- Please note the Pastebin API limitations: guests can create up to 10 new pastes per 24 hours, IP's that make too many requests will be blocked!

### NMAP examples

See `nmap --help` for options.

Parameters                               | Meaning
---------------------------------------- | ---
`-sP --host-timeout 30s --max-retries 3` | Ping scans the network, listening to hosts that respond tp ping for fast host discovery, a given timeout of 30 seconds and a maximum retries of 3
`-p 1-65535 -sV -sS -T4`                 | Full TCP port scan using with service version detection
`-v -sS -A -T4`                          | Prints verbose output, runs stealth syn scan, T4 timing, OS and version detection + traceroute and scripts against target services
`--top-ports 20`                         | Scan 20 most common ports
`-Pn`                                    | No ping
`-O`                                     | Enable OS detection
`-A`                                     | Enable OS detection, version detection, script scanning and traceroute

### Status LED's

Color/Pattern     | Meaning
----------------- | ---
Booting up        | Green blinking
Setting up        | Magenta solid [LED SETUP]
Failures          | Red slow blinking [LED FAIL]
Getting loot      | Yellow single blink [LED ATTACK]
Exfiltrating loot | Yellow double blink [LED STAGE2]
Blink IP ADDRESS  | White blinking (fast blinking = value count, if one of the octets is zero this will be represented as solid for 1 second, long blink = next digit)
Finished          | Green very fast blinking followed by solid [LED FINISH]

## Discussion

[Hak5 Forum Thread](https://forums.hak5.org/topic/52882-payload-network-reconnaissance-payload-for-shark-jack/)
