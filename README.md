
# Payload Library for the Shark Jack by Hak5

This repository contains payloads and extensions for the Hak5 Shark Jack. Community developed payloads are listed and developers are encouraged to create pull requests to make changes to or submit new payloads.

## About the Shark Jack

The Shark Jack is a portable network attack tool optimized for social engineering and opportunistic wired network auditing that makes network reconnaissance, exfiltration and automation quick and easy.


-   [Purchase at Hak5](https://hak5.org/products/shark-jack "Purchase at Hak5")
-   [Documentation](https://docs.hak5.org/shark-jack/ "Documentation")
-   [Forums](https://forums.hak5.org/forum/101-shark-jack/ "Forums")
-   [Discord](https://hak5.org/discord "Discord")

![enter image description here](https://cdn.shopify.com/s/files/1/0068/2142/files/shark_thumb2_300x.jpg)

## Disclaimer
Generally, payloads may execute commands on your device. As such, it is possible for a payload to damage your device. Payloads from this repository are provided AS-IS without warranty. While Hak5 makes a best effort to review payloads, there are no guarantees as to their effectiveness. As with any script, you are advised to proceed with caution.

## Legal
Payloads from this repository are provided for educational purposes only.  Hak5 gear is intended for authorized auditing and security analysis purposes only where permitted subject to local and international laws where applicable. Users are solely responsible for compliance with all laws of their locality. Hak5 LLC and affiliates claim no responsibility for unauthorized or unlawful use.

## Contributing
Once you have developed your payload, you are encouraged to contribute to this repository by submitting a Pull Request. Reviewed and Approved pull requests will add your payload to this repository, where they may be publically available.

Please adhere to the following best practices and style guide when submitting a payload.

### Naming Conventions
Please give your payload a unique and descriptive name. Do not use spaces in payload names. Each payload should be submit into its own directory, with `-` or `_` used in place of spaces, to one of the categories such as exfiltration, phishing, remote_access or recon. Do not create your own category.

### Comments
Payloads should begin with comments specifying at the very least the name of the payload and author. Additional information such as a brief description, the target, any dependencies / prerequisites and the LED status used is helpful.

    # Title:         Sample Nmap Payload for Shark Jack
    # Author:        Hak5
    # Version:       1.2
    #
	# Scans target subnet with Nmap using specified options. Saves each scan result
	# to loot storage folder. Includes SERIAL_WRITE commands for Shark Jack Cable.
	#
	# LED SETUP ... Obtaining IP address from DHCP
	# LED ATTACK ... Scanning
	# LED FINISH ... Scan Complete
   
### Configuration Options
Configurable options should be specified in variables at the top of the payload.txt file

    # Options
    NMAP_OPTIONS="-sP --host-timeout 30s --max-retries 3"
	LOOT_DIR=/root/loot/nmap

### LED
The payload should use common payload states rather than unique color/pattern combinations when possible with an LED command preceding the Stage or `NETMODE`.

    # Initialization
    LED SETUP
    mkdir -p $LOOT_DIR
    COUNT=$(($(ls -l $LOOT_DIR/*.txt | wc -l)+1))
    NETMODE DHCP_CLIENTLED ATTACK
    LED ATTACK
    nmap $NMAP_OPTIONS $SUBNET -oN $LOOT_DIR/nmap-scan_$COUNT.txt
    LED FINISH

Common payload states include a `SETUP`, with may include a `FAIL` if certain conditions are not met. This is typically followed by either a single `ATTACK` or multiple `STAGEs`. More complex payloads may include a `SPECIAL` function to wait until certain conditions are met. Payloads commonly end with a `CLEANUP` phase, such as moving and deleting files or stopping services. A payload may `FINISH` when the objective is complete and the device is safe to eject or turn off. These common payload states correspond to `LED` states.


