# NullSec-NetReaper — Shark Jack Network Recon

**Author:** bad-antics (NullSec)  
**Category:** Recon  
**Target:** Any Ethernet network  
**Version:** 1.0  

## Description

Comprehensive zero-dependency network reconnaissance payload for the Hak5 Shark Jack. Plug into any Ethernet port and get a full network survey in under 2 minutes.

## Features

- **ARP Discovery** — Ping sweep + ARP table enumeration
- **Port Scanning** — Top 25 common ports on all discovered hosts
- **Service Identification** — Maps open ports to known services (SSH, HTTP, SMB, RDP, etc.)
- **Gateway Analysis** — Traceroute to identify upstream network path
- **DNS Reconnaissance** — Reverse DNS lookups on discovered hosts
- **Broadcast Discovery** — Captures broadcast/multicast traffic sources
- **DHCP Fingerprinting** — Extracts DHCP lease information
- **Full Network Config** — Interfaces, routes, assigned IPs

## LED States

| LED      | Color   | Meaning                    |
|----------|---------|----------------------------|
| SETUP    | Magenta | Initializing, waiting for DHCP |
| ATTACK   | Yellow  | Scanning in progress       |
| FINISH   | Green   | Complete, safe to remove   |
| FAIL     | Red     | Error (no network)         |

## Output

Loot is saved to `/root/loot/netreaper_<timestamp>/`:

```
netreaper_20260304_143022/
├── recon_report.txt    # Full formatted report
├── arp_table.txt       # Raw ARP table
├── interfaces.txt      # Network interfaces
└── routes.txt          # Routing table
```

## Usage

1. Copy `payload.sh` to `/root/payloads/switch1/` (or switch2)
2. Set the switch to the corresponding position
3. Plug Shark Jack into target network Ethernet port
4. Wait for green LED
5. Retrieve loot from `/root/loot/`

## Configuration

Edit the top of `payload.sh`:

```bash
SCAN_TIMEOUT=120     # Max scan time (seconds)
TOP_PORTS=100        # Number of ports to scan
```

## Requirements

- Hak5 Shark Jack (v1 or Cable)
- No external dependencies — uses only built-in tools
- Target network must have DHCP

## Sample Output

```
============================================================
  NullSec-NetReaper Network Reconnaissance Report
  Wed Mar  4 14:30:22 UTC 2026
============================================================

[+] NETWORK CONFIGURATION
    Interface:  eth0
    IP Address: 192.168.1.100
    Subnet:     192.168.1.0/24
    Gateway:    192.168.1.1
    DNS:        192.168.1.1

[+] ARP DISCOVERY
    Found 12 live hosts:
    ? (192.168.1.1) at aa:bb:cc:dd:ee:ff on eth0
    ? (192.168.1.5) at 11:22:33:44:55:66 on eth0
    ...

[+] PORT SCANNING (Top ports on discovered hosts)
    --- Host: 192.168.1.1 ---
    Open ports: 22 53 80 443
      22/tcp   SSH
      53/tcp   DNS
      80/tcp   HTTP
      443/tcp  HTTPS

[+] SCAN SUMMARY
    Hosts discovered: 12
    Subnet: 192.168.1.0/24
    Duration: 87 seconds
============================================================
```
