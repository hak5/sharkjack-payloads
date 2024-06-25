
# Payload Library for the [Shark Jack](https://hak5.org/products/shark-jack) by [Hak5](https://hak5.org)

This repository contains payloads and extensions for the Hak5 Shark Jack. Community developed payloads are listed and developers are encouraged to create pull requests to make changes to or submit new payloads.


**Payloads here are written in official DuckyScript™ and Bash specifically for the Shark Jack. Hak5 does NOT guarantee payload functionality.** <a href="#legal"><b>See Legal and Disclaimers</b></a>


<div align="center">
<img src="https://img.shields.io/github/forks/hak5/sharkjack-payloads?style=for-the-badge"/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<img src="https://img.shields.io/github/stars/hak5/sharkjack-payloads?style=for-the-badge"/>
<br/>
<img src="https://img.shields.io/github/commit-activity/y/hak5/sharkjack-payloads?style=for-the-badge">
<img src="https://img.shields.io/github/contributors/hak5/sharkjack-payloads?style=for-the-badge">
</div>
<br/>
<p align="center">
<a href="https://payloadhub.com"><img src="https://cdn.shopify.com/s/files/1/0068/2142/files/payloadhub.png?v=1652474600"></a>
<br/>
<a href="https://payloadhub.com/blogs/payloads/tagged/shark-jack">View Featured Shark Jack Payloads and Leaderboard</a>
<br/><i>Get your payload in front of thousands. Enter to win over $2,000 in prizes in the <a href="https://hak5.org/pages/payload-awards">Hak5 Payload Awards!</a></i>
</p>

<div align="center">
<a href="https://hak5.org/discord"><img src="https://img.shields.io/discord/506629366659153951?label=Hak5%20Discord&style=for-the-badge"></a>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<a href="https://youtube.com/hak5"><img src="https://img.shields.io/youtube/channel/views/UC3s0BtrBJpwNDaflRSoiieQ?label=YouTube%20Views&style=for-the-badge"/></a>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<a href="https://youtube.com/hak5"><img src="https://img.shields.io/youtube/channel/subscribers/UC3s0BtrBJpwNDaflRSoiieQ?style=for-the-badge"/></a>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<a href="https://twitter.com/hak5"><img src="https://img.shields.io/badge/follow-%40hak5-1DA1F2?logo=twitter&style=for-the-badge"/></a>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<a href="https://instagram.com/hak5gear"><img src="https://img.shields.io/badge/Instagram-E4405F?style=for-the-badge&logo=instagram&logoColor=white"/></a>
<br/><br/>

</div>


# Table of contents
<details open>
<ul>
<li><a href="#about-the-shark-jack">About the Shark Jack</a></li>
<li><a href="#build-your-payloads-with-payloadstudio">PayloadStudio (Editor + Compiler)</a></li>
<li><b><a href="#contributing">Contributing Payloads</a></b></li>
<li><a href="#legal"><b>Legal and Disclaimers</b></a></li>
</ul> 
</details>


## Shop
- [Shark Jack Cable](https://shop.hak5.org/products/shark-jack "Purchase the Shark Jack (Cable)")
- [Shark Jack Battery](https://hak5.org/products/shark-jack?variant=21284894670961 "Purchase the Shark Jack (Battery)")
- [PayloadStudio Pro](https://hak5.org/products/payload-studio-pro "Purchase PayloadStudio Pro")
- [Shop All Hak5 Tools](https://shop.hak5.org "Shop All Hak5 Tools")
## Getting Started
- [Build Payloads with PayloadStudio](#build-your-payloads-with-payloadstudio) | [Getting STARTED](https://docs.hak5.org/shark-jack/beginner-guides/ "QUICK START GUIDE") | [Your First Payload](https://docs.hak5.org/shark-jack/writing-payloads/payload-development-basics)
## Documentation / Learn More
-   [Documentation](https://docs.hak5.org/shark-jack "Documentation") 

## Community
*Got Questions? Need some help? Reach out:*
-  [Discord](https://hak5.org/discord/ "Discord") | [Forums](https://forums.hak5.org/forum/101-shark-jack/ "Forums")


## Additional Links
<b> Follow the creators </b><br/>
<p>
	<b>Korben's Socials</b><br/>	
	<a href="https://twitter.com/notkorben"><img src="https://img.shields.io/twitter/follow/notkorben?style=social"/></a>  
	<a href="https://instagram.com/hak5korben"><img src="https://img.shields.io/badge/Instagram-Follow%20@hak5korben-E1306C"/></a>
<br/>
	<b>Darren's Socials</b><br/>
	<a href="https://twitter.com/hak5darren"><img src="https://img.shields.io/twitter/follow/hak5darren?style=social"/></a>  
	<a href="https://instagram.com/hak5darren"><img src="https://img.shields.io/badge/Instagram-Follow%20@hak5darren-E1306C"/></a>
</p>




## About the Shark Jack

Hotplug attack, meet LAN. The Shark Jack is a portable network attack tool optimized for social engineering and opportunistic wired network auditing that makes network reconnaissance, exfiltration and automation quick and easy.


<div align="center">
  <a href="https://hak5.org/products/shark-jack?variant=39688077639793">
    <img src="https://github.com/hak5/sharkjack-payloads/assets/115900893/2edd98e8-ffbc-4563-ac18-195382de3bce" alt="Shark-Jack-Wired" width="300"/>
  </a>
  <a href="https://hak5.org/products/shark-jack?variant=21284894670961">
    <img src="https://github.com/hak5/sharkjack-payloads/assets/115900893/6f2a02e9-1e43-4820-bad1-905631856dc2" alt="Shark-Jack-Battery" width="300"/>
  </a>
</div>

<table style="border-collapse: collapse; width: 100%;">
  <tr>
    <td style="border: 1px solid #dddddd; text-align: center; padding: 10px;">
      <img src="https://hak5.org/cdn/shop/files/shark-jack-cable-6_400x.gif?v=1644945587" alt="Shark Jack Cable" style="max-width: 100%;">
    </td>
    <td style="border: 1px solid #dddddd; padding: 10px;">
      <div style="text-align: center;">
        <strong>AT THE READY</strong>
      </div>
      Perfect for physical engagements. Keep this opportunistic wired network attack platform at the ready for intel & recon at a moments notice.<br><br>
      Even get live results and instant access to a Linux shell on the LAN with the Cable edition as shown.
    </td>
  </tr>
  <tr>
    <td style="border: 1px solid #dddddd; text-align: center; padding: 10px;">
      <img src="https://hak5.org/cdn/shop/files/payload_252e1a50-60c6-4ab1-9b76-96e664cfdf2a_400x.png?v=1614318413" alt="Shark Jack Cable" style="max-width: 100%;">
    </td>
    <td style="border: 1px solid #dddddd; padding: 10px;">
      <div style="text-align: center;">
        <strong>SIMPLE SCRIPTING</strong>
      </div>
      The simple scripting language lets you quickly develop payloads using bash and familiar Linux network tools so you can automate any attack.
    </td>
  </tr>
  <tr>
    <td style="border: 1px solid #dddddd; text-align: center; padding: 10px;">
      <img src="https://hak5.org/cdn/shop/products/shark-jack-cable-1_600x.jpg?v=1644946946" alt="Shark Jack Battery" style="max-width: 100%;">
    </td>
    <td style="border: 1px solid #dddddd; padding: 10px;">
      <div style="text-align: center;">
        <strong>LINUX UNDER THE HOOD</strong>
      </div>
      Root access with all the fixings and find familiar command line network utilities at the ready.<br><br>
      Just SSH in, or even drop into a shell over USB-C serial with the Cable edition. Widely supported by Android OTG + Windows, Mac & Linux.
    </td>
  </tr>
</table>


<h1><a href="https://payloadstudio.hak5.org">Build your payloads with PayloadStudio</a></h1>
<p align="center">
Take your DuckyScript™ payloads to the next level with this full-featured,<b> web-based (entirely client side) </b> development environment.
<br/>
<a href="https://payloadstudio.hak5.org"><img width="500px" src="https://cdn.shopify.com/s/files/1/0068/2142/products/payload-studio-icon_2000x.png"></a>
<br/>
<i>Payload studio features all of the conveniences of a modern IDE, right from your browser. From syntax highlighting and auto-completion to live error-checking and repo synchronization - building payloads for Hak5 hotplug tools has never been easier!
<br/><br/>
Supports your favorite Hak5 gear - USB Rubber Ducky, Bash Bunny, Key Croc, Shark Jack, Packet Squirrel & LAN Turtle!
<br/><br/></i><br/>
<a href="https://hak5.org/products/payload-studio-pro">Become a PayloadStudio Pro</a> and <b> Unleash your hacking creativity! </b>
<br/>
OR
<br/>
<a href="https://payloadstudio.hak5.org/community/"> Try Community Edition FREE</a> 
<br/><br/>
<img src="https://cdn.shopify.com/s/files/1/0068/2142/files/themes1_1_600x.gif?v=1659642557">
<br/>
<i> Payload Studio Themes Preview GIF </i>
<br/><br/>
<img src="https://cdn.shopify.com/s/files/1/0068/2142/files/AUTOCOMPLETE3_600x.gif?v=1659640513">
<br/>
<i> Payload Studio Autocomplete Preview GIF </i>
</p>


<h1><a href='https://payloadhub.com'>Contributing</a></h1>

<p align="center">
<a href="https://payloadhub.com"><img src="https://cdn.shopify.com/s/files/1/0068/2142/files/payloadhub.png?v=1652474600"></a>
<br/>
<a href="https://payloadhub.com">View Featured Payloads and Leaderboard </a>
</p>

# Please adhere to the following best practices and style guides when submitting a payload.

Once you have developed your payload, you are encouraged to contribute to this repository by submitting a Pull Request. Reviewed and Approved pull requests will add your payload to this repository, where they may be publically available.

Please include all resources required for the payload to run. If needed, provide a README.md in the root of your payload's directory to explain things such as intended use, required configurations, or anything that will not easily fit in the comments of the payload.txt itself. Please make sure that your payload is tested, and free of errors. If your payload contains (or is based off of) the work of other's please make sure to cite their work giving proper credit. 


### Purely Destructive payloads will not be accepted. No, it's not "just a prank".
Subject to change. Please ensure any submissions meet the [latest version](https://github.com/hak5/usbrubberducky-payloads/blob/master/README.md) of these standards before submitting a Pull Request.


## Naming Conventions
Please give your payload a unique, descriptive and appropriate name. Do not use spaces in payload, directory or file names. Each payload should be submit into its own directory, with `-` or `_` used in place of spaces, to one of the categories such as exfiltration, phishing, remote_access or recon. Do not create your own category.

## Staged Payloads
"Staged payloads" are payloads that **download** code from some resource external to the payload.txt. 

While staging code used in payloads is often useful and appropriate, using this (or another) github repository as the means of deploying those stages is not. This repository is **not a CDN for deployment on target systems**. 

Staged code should be copied to and hosted on an appropriate server for doing so **by the end user** - Github and this repository are simply resources for sharing code among developers and users.
See: [GitHub acceptable use policies](https://docs.github.com/en/site-policy/acceptable-use-policies/github-acceptable-use-policies#5-site-access-and-safety)

Additionally, any source code that is intended to be staged **(by the end user on the appropriate infrastructure)** should be included in any payload submissions either in the comments of the payload itself or as a seperate file. **Links to staged code are unacceptable**; not only for the reasons listed above but also for version control and user safety reasons. Arbitrary code hidden behind some pre-defined external resource via URL in a payload could be replaced at any point in the future unbeknownst to the user -- potentially turning a harmless payload into something dangerous.

### Including URLs
URLs used for retrieving staged code should refer exclusively to **example.com** using a bash variable in any payload submissions [see Payload Configuration section below](https://github.com/hak5/usbrubberducky-payloads/blob/master/README.md#payload-configuration). 

### Staged Example

**Example scenario: your payload downloads a script and the executes it on a target machine.**
- Include the script in the directory with your payload
- Provide instructions for the user to move the script to the appropriate hosting service.
- Provide a bash variable with the placeholder example.com for the user to easily configure once they have hosted the script

[Simple Example of this style of payload](https://github.com/hak5/usbrubberducky-payloads/tree/master/payloads/library/exfiltration/Printer-Recon)

### Payload Configuration
Be sure to take the following into careful consideration to ensure your payload is easily tested, used and maintained.
In many cases, payloads will require some level of configuration **by the end payload user**. 

- Abstract configuration(s) for ease of use. Use bash assignment variables where possible. 
- Remember to use PLACEHOLDERS for configurable portions of your payload - do not share your personal URLs, API keys, Passphrases, etc...
- URLs to staged payloads SHOULD NOT BE INCLUDED. URLs should be replaced by example.com. Provide instructions on how to specific resources should be hosted on the appropriate infrastructure.
- Make note of both REQUIRED and OPTIONAL configuration(s) in your payload using bash comments at the top of your payload or "inline" where applicable.

```
Example: 
	BEGINNING OF PAYLOAD 
	... Payload Documentation... 
        #!/bin/bash
	# CONFIGURATION
	# REQUIRED - Provide URL used for Example
	MY_TARGET_URL="example.com"
	nmap $MY_TARGET_URL
	...
```

### Payload Documentation 
Payloads should begin with `#` bash comments specifying the title of the payload, the author, the target, and a brief description.

```
Example:
	BEGINNING OF PAYLOAD
	#!/bin/bash
	# Title: Example Payload
	# Author: Korben Dallas
	# Description: scans target with nmap
	# Props: Hak5, Darren Kitchen, Korben
	# Version: 1.0
	# Category: General
```


### Binaries
Binaries may not be accepted in this repository. If a binary is used in conjunction with the payload, please document where it or its source may be obtained.

   
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

<h1><a href="https://hak5.org/pages/policy">Legal</a></h1>

Payloads from this repository are provided for educational purposes only.  Hak5 gear is intended for authorized auditing and security analysis purposes only where permitted subject to local and international laws where applicable. Users are solely responsible for compliance with all laws of their locality. Hak5 LLC and affiliates claim no responsibility for unauthorized or unlawful use.

Shark Jack and DuckyScript are the trademarks of Hak5 LLC. Copyright © 2010 Hak5 LLC. All rights reserved. No part of this work may be reproduced or transmitted in any form or by any means without prior written permission from the copyright owner.
Shark Jack and DuckyScript are subject to the Hak5 license agreement (https://hak5.org/license)
DuckyScript is the intellectual property of Hak5 LLC for the sole benefit of Hak5 LLC and its licensees. To inquire about obtaining a license to use this material in your own project, contact us. Please report counterfeits and brand abuse to legal@hak5.org.
This material is for education, authorized auditing and analysis purposes where permitted subject to local and international laws. Users are solely responsible for compliance. Hak5 LLC claims no responsibility for unauthorized or unlawful use.
Hak5 LLC products and technology are only available to BIS recognized license exception ENC favorable treatment countries pursuant to US 15 CFR Supplement No 3 to Part 740.

See also: 

[Hak5 Software License Agreement](https://shop.hak5.org/pages/software-license-agreement)
	
[Terms of Service](https://shop.hak5.org/pages/terms-of-service)

# Disclaimer
<h3><b>As with any script, you are advised to proceed with caution.</h3></b>
<h3><b>Generally, payloads may execute commands on your device. As such, it is possible for a payload to damage your device. Payloads from this repository are provided AS-IS without warranty. While Hak5 makes a best effort to review payloads, there are no guarantees as to their effectiveness.</h3></b>
