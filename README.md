# ASL3 + SHARI SA818 + Allmon3 Installer

Interactive installation script for **AllStarLink 3 (ASL3)** on a Raspberry Pi, with optional **SHARI SA818** USB radio interface support and the **Allmon3** web interface.

## Features

- Interactive wizard using `whiptail` (no manual config file editing)
- **Bilingual** — choose Dutch or English at startup
- Optional SHARI SA818 UHF/VHF radio programming via serial (`/dev/ttyUSB0`)
- Installs and configures:
  - AllStarLink 3 (`asl3` package from official ASL repo)
  - Asterisk config files: `rpt.conf`, `simpleusb.conf`, `iax.conf`, `extensions.conf`, `manager.conf`
  - Allmon3 web interface on Apache (`http://IP/allmon3`)
- Hub node auto-connect on startup (optional)
- ALSA fix for Raspberry Pi (`vc4-kms-v3d,noaudio`) to prevent HDMI stealing the USB audio card slot
- Summary screen before installation begins — confirm or cancel

## Requirements

| Requirement | Details |
|---|---|
| OS | Raspberry Pi OS 64-bit Lite (Debian Bookworm) |
| Architecture | arm64 (Raspberry Pi) or amd64 (Debian 12) |
| Access | Root / `sudo` |
| Network | Internet connection (downloads ASL3 apt repo + packages) |
| AllStarLink account | Node number + password from [allstarlink.org](https://www.allstarlink.org) |
| SHARI SA818 *(optional)* | C-Media CM108 USB audio interface with SA818 module |

## Usage

```bash
sudo bash asl3-shari-allmon3-install.sh
```

The script will guide you through all settings interactively. No prior editing required.

## What the Installer Configures

### Step 1 — Language & input

- Choose Dutch or English
- Enter: Linux username, node number, node password, callsign
- Choose whether a SHARI SA818 is connected

### Step 2 — System update

- `apt-get update && upgrade`
- Installs: `curl`, `wget`, `ca-certificates`, `gnupg`, `apache2`, `python3-serial`

### Step 3 — ASL3 installation

- Adds the official ASL3 apt repository (`repo.allstarlink.org`)
- Installs kernel headers (required for `dahdi-dkms`)
- Installs the `asl3` package

### Step 4 — ASL3 configuration

Writes the following Asterisk config files:

| File | Purpose |
|---|---|
| `rpt.conf` | Node definition, functions, DTMF commands, hub auto-connect |
| `simpleusb.conf` | USB audio interface, RX/TX mix levels |
| `rpt_http_registrations.conf` | Node registration at AllStarLink |
| `extensions.conf` | Adds `NODE` variable to `[globals]` |
| `iax.conf` | IAX2 registration for AllStar DNS |
| `manager.conf` | AMI interface for Allmon3 (random password, localhost only) |

### Step 5 — SHARI SA818 *(if selected)*

- Applies ALSA fix in `/boot/firmware/config.txt`
- Writes `/etc/sa818.conf` with radio parameters
- Programs the SA818 via serial port using `AT+DMOSETGROUP` commands:
  - RX/TX frequency
  - Bandwidth (Narrow 12.5 kHz / Wide 25 kHz)
  - CTCSS tone TX/RX (optional)
  - Squelch level (0–8)
  - Volume (1–8)

### Step 6 & 7 — Allmon3 installation & configuration

- Installs `allmon3` from the ASL3 apt repository
- Enables Apache modules: `proxy`, `proxy_http`, `rewrite`
- Writes `/etc/allmon3/allmon3.ini` pointing to the local AMI interface
- Creates an Allmon3 web user with `allmon3-passwd`

### Step 8 — Services

- Enables and starts: `asterisk`, `allmon3`, `apache2`
- Reboots the system to apply all changes

## After Installation

| Item | Details |
|---|---|
| Allmon3 web interface | `http://<IP>/allmon3` |
| Login | Username and password set during installation |
| Node registration | Registers automatically at `register.allstarlink.org` |
| Hub auto-connect | If configured, node connects to hub on Asterisk startup |

## Audio Levels (SimpleUSB)

The installer prompts for mix levels. Defaults suited for the SHARI SA818:

| Setting | Default | Range |
|---|---|---|
| RX mix level | 800 | 0–999 |
| TX mix A level | 600 | 0–999 |
| TX mix B level | 500 | 0–999 |

Fine-tune after installation with `simpleusb-tune-menu` or by editing `/etc/asterisk/simpleusb.conf`.

## CTCSS Tones

CTCSS tones are optional. Leave empty for carrier squelch (no tone).  
Supported tones follow the standard SA818 CTCSS table (67.0–250.3 Hz).

## SHARI SA818 Serial Port

The script auto-detects `/dev/ttyUSB0` or `/dev/ttyAMA0`. If programming fails, you can reprogram manually:

```bash
sudo python3 /usr/local/sbin/sa818-prog.py
```

## Troubleshooting

**Asterisk not connecting to AllStarLink**
```bash
asterisk -r
rpt show nodes
```

**ALSA device not found (wrong card order)**  
Check that `/boot/firmware/config.txt` contains `dtoverlay=vc4-kms-v3d,noaudio`.  
List ALSA devices: `aplay -l`

**SA818 programming failed**  
Verify the USB cable is data-capable (not charge-only) and the device is visible:
```bash
ls /dev/ttyUSB*
dmesg | grep tty
```

**Allmon3 shows no nodes**  
Check AMI connectivity: the password in `/etc/allmon3/allmon3.ini` must match `/etc/asterisk/manager.conf`.

## License

MIT — free to use and modify. Contributions welcome.

---

*Tested on Raspberry Pi 3/4/5 with Raspberry Pi OS Bookworm 64-bit Lite.*
