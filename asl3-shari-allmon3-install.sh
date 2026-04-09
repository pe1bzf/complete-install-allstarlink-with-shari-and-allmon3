#!/bin/bash
# =============================================================================
# ASL3 + SHARI SA818 + Allmon3 Installatiescript / Installation Script
# =============================================================================
# Ondersteunde omgeving / Supported environment:
#   - Raspberry Pi OS 64-bit Lite (Debian Bookworm)
#   - SHARI SA818 USB interface (C-Media USB, ALSA)
#   - AllStarLink 3 (ASL3)
#   - Allmon3 webinterface (bereikbaar op / available at http://IP/allmon3)
#
# Gebruik / Usage: sudo bash asl3-shari-allmon3-install.sh
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[${L_WARN:-WARN}]${NC} $1"; }
err()  { echo -e "${RED}[${L_ERR:-ERROR}]${NC} $1"; exit 1; }
step() { echo -e "\n${BOLD}${CYAN}=== $1 ===${NC}"; }

# =============================================================================
# TAAL / LANGUAGE SELECTION
# =============================================================================

command -v whiptail &>/dev/null || {
  echo "whiptail not found / niet gevonden. Install with: apt install whiptail"
  exit 1
}

LANG_SEL=$(whiptail --title "Language / Taal" --menu \
  "Choose your language / Kies uw taal:" \
  10 52 2 \
  "NL" "Nederlands" \
  "EN" "English" \
  3>&1 1>&2 2>&3) || LANG_SEL="NL"

# =============================================================================
# TEKST DEFINITIES / STRING DEFINITIONS
# =============================================================================

if [ "$LANG_SEL" = "EN" ]; then
  L_WARN="WARNING"
  L_ERR="ERROR"
  L_ROOT_ERR="Run this script as root: sudo bash $0"
  L_OS_ERR="This script requires Raspberry Pi OS / Debian 12 Bookworm. Detected:"
  L_OS_OK="OS: Debian"
  L_CANCELLED="Installation cancelled."

  WT_TITLE="ASL3 + SHARI SA818 + Allmon3 Installation"

  L_WELCOME="This script installs and configures:

  * AllStarLink 3 (ASL3)
  * SHARI SA818 USB interface
  * Allmon3 web interface (http://IP/allmon3)

Press Enter for the default value in each field.
Press Escape or Cancel to abort."

  L_RPI_USER_PROMPT="RPi username (Linux login on this Pi):"
  L_ALLSTAR_INFO="AllStarLink credentials

Node number and password can be found at allstarlink.org
after logging in under: Portal > Node Settings."
  L_NODE_NUM_PROMPT="Node number (e.g. 40000):"
  L_NODE_NUM_ERR="Node number is required."
  L_NODE_PASS_PROMPT="Node password (from allstarlink.org portal):"
  L_NODE_PASS_ERR="Node password is required."
  L_CALLSIGN_PROMPT="Callsign (e.g. PD0ABC):"
  L_CALLSIGN_ERR="Callsign is required."
  L_FREQ_RX_PROMPT="RX frequency (MHz):"
  L_FREQ_TX_PROMPT="TX frequency (MHz):"
  L_BW_PROMPT="Bandwidth:"
  L_BW_NARROW="Narrow (12.5 kHz) — standard for Netherlands"
  L_BW_WIDE="Wide (25 kHz)"
  L_SQ_PROMPT="Squelch level (0-8):"
  L_VOL_PROMPT="SA818 volume (1-8):"
  L_CTCSS_TX_PROMPT="CTCSS tone TX (e.g. 88.5 — leave empty for none):"
  L_CTCSS_RX_PROMPT="CTCSS tone RX (e.g. 88.5 — leave empty for none):"
  L_RXMIX_PROMPT="RX mix level (0-999) — default for SHARI SA818:"
  L_TXMIXA_PROMPT="TX mix A level (0-999):"
  L_TXMIXB_PROMPT="TX mix B level (0-999):"
  L_WEBUSER_PROMPT="Allmon3 username:"
  L_WEBPASS_PROMPT="Allmon3 password:"
  L_WEBPASS_ERR="Password is required."
  L_WEBPASS2_PROMPT="Confirm password:"
  L_WEBPASS_MISMATCH="Passwords do not match. Please try again."

  L_SUMMARY_TITLE="ASL3 + SHARI SA818 + Allmon3 Installation — Summary"
  L_SUMMARY_INTRO="Review the settings before installation:"
  L_SUMMARY_USER="System user        "
  L_SUMMARY_NODE="Node number        "
  L_SUMMARY_PASS="Node password      "
  L_SUMMARY_CALL="Callsign           "
  L_SUMMARY_FREQ="Frequency RX/TX    "
  L_SUMMARY_BW="Bandwidth          "
  L_SUMMARY_SQ="Squelch            "
  L_SUMMARY_VOL="SA818 volume       "
  L_SUMMARY_CTCSS="CTCSS TX/RX        "
  L_SUMMARY_MIX="RX/TXA/TXB mix     "
  L_SUMMARY_WEBUSER="Allmon3 user       "
  L_SUMMARY_CONFIRM="Proceed with installation?"
  L_CTCSS_NONE="none"

  L_STEP2="Update system and install dependencies"
  L_STEP3="Install AllStarLink 3 (ASL3)"
  L_STEP4="Configure ASL3"
  L_STEP5="Configure SHARI SA818"
  L_STEP6="Install Allmon3"
  L_STEP7="Configure Allmon3"
  L_STEP8="Create Allmon3 user"
  L_STEP9="Start all services"

  L_SYS_OK="System updated"
  L_ASL_REPO="Adding ASL3 apt repository..."
  L_ASL_REPO_ERR="Could not download ASL3 repo package."
  L_KERNEL_HEADERS="Installing kernel headers (required for dahdi-dkms)..."
  L_KERNEL_HEADERS_WARN="Kernel headers not found — dahdi-dkms compilation may fail"
  L_ASL_INSTALLED="ASL3 installed"
  L_ASL_ALREADY="ASL3 is already installed"
  L_ASL_ERR="ASL3 installation failed. Run 'apt-get install -y asl3' manually for details."
  L_RPT_INFO="Configuring rpt.conf..."
  L_RPT_OK="rpt.conf written"
  L_USB_INFO="Configuring simpleusb.conf..."
  L_USB_OK="simpleusb.conf written"
  L_REG_INFO="Configuring node registration..."
  L_REG_OK="Registration configured"
  L_EXT_INFO="Updating extensions.conf..."
  L_EXT_OK="extensions.conf updated"
  L_MGR_INFO="Configuring manager.conf..."
  L_MGR_OK="manager.conf written"
  L_SA818_PROG="Programming SA818 via shari-config..."
  L_SA818_PROG_OK="SA818 programmed"
  L_SA818_PROG_WARN="SA818 programming failed — run manually: sudo shari-config"
  L_SA818_NOTFOUND="shari-config not found — SA818 will be configured on first reboot"
  L_AM3_INSTALLED="Allmon3 installed"
  L_APACHE_OK="Apache modules enabled"
  L_APACHE_CONF_WARN="Allmon3 Apache conf not found via a2enconf"
  L_SERVICES_OK="All services started"

  L_DONE_TITLE="  INSTALLATION COMPLETE!"
  L_DONE_NODE="AllStarLink node"
  L_DONE_FREQ="Frequency"
  L_DONE_WEB="Allmon3"
  L_DONE_LOGIN="Login"
  L_DONE_PASS_HINT="[your password]"
  L_REBOOT_PROMPT="Press Enter to reboot (or Ctrl+C to cancel)... "

else
  # Nederlands (standaard)
  L_WARN="WAARSCHUWING"
  L_ERR="FOUT"
  L_ROOT_ERR="Voer dit script uit als root: sudo bash $0"
  L_OS_ERR="Dit script vereist Raspberry Pi OS / Debian 12 Bookworm. Gedetecteerd:"
  L_OS_OK="OS: Debian"
  L_CANCELLED="Installatie geannuleerd."

  WT_TITLE="ASL3 + SHARI SA818 + Allmon3 Installatie"

  L_WELCOME="Dit script installeert en configureert:

  * AllStarLink 3 (ASL3)
  * SHARI SA818 USB interface
  * Allmon3 webinterface (http://IP/allmon3)

Druk Enter voor de standaardwaarde bij elk veld.
Druk Escape of Annuleren om te stoppen."

  L_RPI_USER_PROMPT="RPi gebruikersnaam (Linux login op deze Pi):"
  L_ALLSTAR_INFO="AllStarLink gegevens

Nodenummer en wachtwoord vind je op allstarlink.org
na inloggen onder: Portal > Node Settings."
  L_NODE_NUM_PROMPT="Nodenummer (bijv. 40000):"
  L_NODE_NUM_ERR="Nodenummer is verplicht."
  L_NODE_PASS_PROMPT="Node wachtwoord (van allstarlink.org portaal):"
  L_NODE_PASS_ERR="Node wachtwoord is verplicht."
  L_CALLSIGN_PROMPT="Roepnaam (bijv. PD0ABC):"
  L_CALLSIGN_ERR="Roepnaam is verplicht."
  L_FREQ_RX_PROMPT="Frequentie RX (MHz):"
  L_FREQ_TX_PROMPT="Frequentie TX (MHz):"
  L_BW_PROMPT="Bandbreedte:"
  L_BW_NARROW="Smalband (12.5 kHz) — standaard voor Nederland"
  L_BW_WIDE="Breedband (25 kHz)"
  L_SQ_PROMPT="Squelch niveau (0-8):"
  L_VOL_PROMPT="SA818 volume (1-8):"
  L_CTCSS_TX_PROMPT="CTCSS toon TX (bijv. 88.5 — leeg = geen):"
  L_CTCSS_RX_PROMPT="CTCSS toon RX (bijv. 88.5 — leeg = geen):"
  L_RXMIX_PROMPT="RX mix niveau (0-999) — standaard voor SHARI SA818:"
  L_TXMIXA_PROMPT="TX mix A niveau (0-999):"
  L_TXMIXB_PROMPT="TX mix B niveau (0-999):"
  L_WEBUSER_PROMPT="Allmon3 gebruikersnaam:"
  L_WEBPASS_PROMPT="Allmon3 wachtwoord:"
  L_WEBPASS_ERR="Wachtwoord is verplicht."
  L_WEBPASS2_PROMPT="Bevestig wachtwoord:"
  L_WEBPASS_MISMATCH="Wachtwoorden komen niet overeen. Probeer opnieuw."

  L_SUMMARY_TITLE="ASL3 + SHARI SA818 + Allmon3 Installatie — Samenvatting"
  L_SUMMARY_INTRO="Controleer de instellingen voor installatie:"
  L_SUMMARY_USER="Systeem gebruiker  "
  L_SUMMARY_NODE="Node nummer        "
  L_SUMMARY_PASS="Node wachtwoord    "
  L_SUMMARY_CALL="Roepnaam           "
  L_SUMMARY_FREQ="Frequentie RX/TX   "
  L_SUMMARY_BW="Bandbreedte        "
  L_SUMMARY_SQ="Squelch            "
  L_SUMMARY_VOL="SA818 volume       "
  L_SUMMARY_CTCSS="CTCSS TX/RX        "
  L_SUMMARY_MIX="RX/TXA/TXB mix     "
  L_SUMMARY_WEBUSER="Allmon3 gebruiker  "
  L_SUMMARY_CONFIRM="Doorgaan met installatie?"
  L_CTCSS_NONE="geen"

  L_STEP2="Systeem bijwerken en dependencies installeren"
  L_STEP3="AllStarLink 3 (ASL3) installeren"
  L_STEP4="ASL3 configureren"
  L_STEP5="SHARI SA818 configureren"
  L_STEP6="Allmon3 installeren"
  L_STEP7="Allmon3 configureren"
  L_STEP8="Allmon3 gebruiker aanmaken"
  L_STEP9="Alle services starten"

  L_SYS_OK="Systeem bijgewerkt"
  L_ASL_REPO="ASL3 apt repository toevoegen..."
  L_ASL_REPO_ERR="Kon ASL3 repo pakket niet downloaden."
  L_KERNEL_HEADERS="Kernel headers installeren (vereist voor dahdi-dkms)..."
  L_KERNEL_HEADERS_WARN="Kernel headers niet gevonden — dahdi-dkms compilatie kan mislukken"
  L_ASL_INSTALLED="ASL3 geïnstalleerd"
  L_ASL_ALREADY="ASL3 is al geïnstalleerd"
  L_ASL_ERR="ASL3 installatie mislukt. Voer 'apt-get install -y asl3' handmatig uit voor meer details."
  L_RPT_INFO="rpt.conf configureren..."
  L_RPT_OK="rpt.conf geschreven"
  L_USB_INFO="simpleusb.conf configureren..."
  L_USB_OK="simpleusb.conf geschreven"
  L_REG_INFO="Node registratie configureren..."
  L_REG_OK="Registratie geconfigureerd"
  L_EXT_INFO="extensions.conf bijwerken..."
  L_EXT_OK="extensions.conf bijgewerkt"
  L_MGR_INFO="manager.conf configureren..."
  L_MGR_OK="manager.conf geschreven"
  L_SA818_PROG="SA818 programmeren via shari-config..."
  L_SA818_PROG_OK="SA818 geprogrammeerd"
  L_SA818_PROG_WARN="SA818 programmeren mislukt — handmatig uitvoeren: sudo shari-config"
  L_SA818_NOTFOUND="shari-config niet gevonden — SA818 wordt bij eerste reboot geconfigureerd"
  L_AM3_INSTALLED="Allmon3 geïnstalleerd"
  L_APACHE_OK="Apache modules ingeschakeld"
  L_APACHE_CONF_WARN="Allmon3 Apache conf niet gevonden via a2enconf"
  L_SERVICES_OK="Alle services gestart"

  L_DONE_TITLE="  INSTALLATIE VOLTOOID!"
  L_DONE_NODE="AllStarLink node"
  L_DONE_FREQ="Frequentie"
  L_DONE_WEB="Allmon3"
  L_DONE_LOGIN="Login"
  L_DONE_PASS_HINT="[jouw wachtwoord]"
  L_REBOOT_PROMPT="Druk Enter om te herstarten (of Ctrl+C om te annuleren)... "
fi

# =============================================================================
# SYSTEEM CHECKS
# =============================================================================

# Root check
[ "$EUID" -ne 0 ] && err "$L_ROOT_ERR"

# OS check — ASL3 vereist Debian 12 Bookworm
CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
if [ "$CODENAME" != "bookworm" ]; then
  err "$L_OS_ERR ${CODENAME}"
fi
ok "${L_OS_OK} ${CODENAME} — OK"

# =============================================================================
# STAP 1: CONFIGURATIE INVOER (whiptail)
# =============================================================================

whiptail --title "$WT_TITLE" --msgbox "$L_WELCOME" 14 64

# --- Systeemgegevens ---
RPI_USER=$(whiptail --title "$WT_TITLE" \
  --inputbox "$L_RPI_USER_PROMPT" \
  8 60 "pi" 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }
RPI_USER=${RPI_USER:-pi}

# --- AllStarLink gegevens ---
whiptail --title "$WT_TITLE" --msgbox "$L_ALLSTAR_INFO" 10 60

NODE_NUM=$(whiptail --title "$WT_TITLE" \
  --inputbox "$L_NODE_NUM_PROMPT" \
  8 60 "" 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }
[ -z "$NODE_NUM" ] && err "$L_NODE_NUM_ERR"

NODE_PASS=$(whiptail --title "$WT_TITLE" \
  --passwordbox "$L_NODE_PASS_PROMPT" \
  8 60 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }
[ -z "$NODE_PASS" ] && err "$L_NODE_PASS_ERR"

CALLSIGN=$(whiptail --title "$WT_TITLE" \
  --inputbox "$L_CALLSIGN_PROMPT" \
  8 60 "" 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }
[ -z "$CALLSIGN" ] && err "$L_CALLSIGN_ERR"

# --- SA818 / Radio configuratie ---
SA818_FREQ_RX=$(whiptail --title "$WT_TITLE" \
  --inputbox "$L_FREQ_RX_PROMPT" \
  8 60 "430.0000" 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }
SA818_FREQ_RX=${SA818_FREQ_RX:-430.0000}

SA818_FREQ_TX=$(whiptail --title "$WT_TITLE" \
  --inputbox "$L_FREQ_TX_PROMPT" \
  8 60 "$SA818_FREQ_RX" 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }
SA818_FREQ_TX=${SA818_FREQ_TX:-$SA818_FREQ_RX}

SA818_BW=$(whiptail --title "$WT_TITLE" \
  --menu "$L_BW_PROMPT" 12 64 2 \
  "Narrow" "$L_BW_NARROW" \
  "Wide"   "$L_BW_WIDE" \
  3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }

SA818_SQ=$(whiptail --title "$WT_TITLE" \
  --inputbox "$L_SQ_PROMPT" \
  8 60 "1" 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }
SA818_SQ=${SA818_SQ:-1}

SA818_VOL=$(whiptail --title "$WT_TITLE" \
  --inputbox "$L_VOL_PROMPT" \
  8 60 "1" 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }
SA818_VOL=${SA818_VOL:-1}

SA818_CTCSS_TX=$(whiptail --title "$WT_TITLE" \
  --inputbox "$L_CTCSS_TX_PROMPT" \
  8 60 "" 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }

SA818_CTCSS_RX=$(whiptail --title "$WT_TITLE" \
  --inputbox "$L_CTCSS_RX_PROMPT" \
  8 60 "" 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }

# --- Audio afstemming (SimpleUSB) ---
RXMIX=$(whiptail --title "$WT_TITLE" \
  --inputbox "$L_RXMIX_PROMPT" \
  8 60 "800" 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }
RXMIX=${RXMIX:-800}

TXMIXA=$(whiptail --title "$WT_TITLE" \
  --inputbox "$L_TXMIXA_PROMPT" \
  8 60 "600" 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }
TXMIXA=${TXMIXA:-600}

TXMIXB=$(whiptail --title "$WT_TITLE" \
  --inputbox "$L_TXMIXB_PROMPT" \
  8 60 "500" 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }
TXMIXB=${TXMIXB:-500}

# --- Allmon3 webinterface ---
WEB_USER=$(whiptail --title "$WT_TITLE" \
  --inputbox "$L_WEBUSER_PROMPT" \
  8 60 "admin" 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }
WEB_USER=${WEB_USER:-admin}

while true; do
  WEB_PASS=$(whiptail --title "$WT_TITLE" \
    --passwordbox "$L_WEBPASS_PROMPT" \
    8 60 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }
  if [ -z "$WEB_PASS" ]; then
    whiptail --title "$WT_TITLE" --msgbox "$L_WEBPASS_ERR" 8 40
    continue
  fi
  WEB_PASS2=$(whiptail --title "$WT_TITLE" \
    --passwordbox "$L_WEBPASS2_PROMPT" \
    8 60 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }
  [ "$WEB_PASS" = "$WEB_PASS2" ] && break
  whiptail --title "$WT_TITLE" --msgbox "$L_WEBPASS_MISMATCH" 8 52
done

# --- Samenvatting / Summary ---
CTCSS_TX_DISP="${SA818_CTCSS_TX:-$L_CTCSS_NONE}"
CTCSS_RX_DISP="${SA818_CTCSS_RX:-$L_CTCSS_NONE}"

whiptail --title "$L_SUMMARY_TITLE" --yesno \
"${L_SUMMARY_INTRO}

  ${L_SUMMARY_USER}: ${RPI_USER}
  ${L_SUMMARY_NODE}: ${NODE_NUM}
  ${L_SUMMARY_PASS}: ****
  ${L_SUMMARY_CALL}: ${CALLSIGN}
  ${L_SUMMARY_FREQ}: ${SA818_FREQ_RX} / ${SA818_FREQ_TX} MHz
  ${L_SUMMARY_BW}: ${SA818_BW}
  ${L_SUMMARY_SQ}: ${SA818_SQ}
  ${L_SUMMARY_VOL}: ${SA818_VOL}
  ${L_SUMMARY_CTCSS}: ${CTCSS_TX_DISP} / ${CTCSS_RX_DISP}
  ${L_SUMMARY_MIX}: ${RXMIX} / ${TXMIXA} / ${TXMIXB}
  ${L_SUMMARY_WEBUSER}: ${WEB_USER}

${L_SUMMARY_CONFIRM}" \
22 66 || { echo "$L_CANCELLED"; exit 0; }

# =============================================================================
# STAP 2: SYSTEEM VOORBEREIDING
# =============================================================================
step "$L_STEP2"

apt-get update -q
apt-get upgrade -y -q
apt-get install -y -q \
  curl wget ca-certificates gnupg \
  apache2 argon2
ok "$L_SYS_OK"

# =============================================================================
# STAP 3: ASL3 INSTALLATIE
# =============================================================================
step "$L_STEP3"

if ! dpkg -l asl3 &>/dev/null; then
  info "$L_ASL_REPO"
  ASL_REPO_URL="https://repo.allstarlink.org/public/asl-apt-repos.deb12_all.deb"
  curl -fsSL "$ASL_REPO_URL" -o /tmp/asl-apt-repos.deb || \
    err "$L_ASL_REPO_ERR"
  dpkg -i /tmp/asl-apt-repos.deb
  apt-get update -q

  info "$L_KERNEL_HEADERS"
  apt-get install -y -q raspberrypi-kernel-headers || \
    apt-get install -y -q linux-headers-$(uname -r) || \
    warn "$L_KERNEL_HEADERS_WARN"

  apt-get install -y -q asl3 || \
    err "$L_ASL_ERR"
  ok "${L_ASL_INSTALLED} ($(dpkg -l asl3 | tail -1 | awk '{print $3}'))"
else
  ok "${L_ASL_ALREADY} ($(dpkg -l asl3 | tail -1 | awk '{print $3}'))"
fi

# ASL3 stoppen voor configuratie
systemctl stop asterisk 2>/dev/null || true

# =============================================================================
# STAP 4: ASL3 CONFIGURATIE
# =============================================================================
step "$L_STEP4"

# --- rpt.conf ---
info "$L_RPT_INFO"
cat > /etc/asterisk/rpt.conf << RPTEOF
[general]
node_lookup_method = dns

[nodes]
${NODE_NUM} = radio@127.0.0.1/${NODE_NUM},NONE

[node-main](!)
rxchannel = SimpleUSB/\${NODE}
duplex = 1
hangtime = 400
holdofftelem = 1
idrecording = |i${CALLSIGN}
idtime = 540000
politeid = 30000
unlinkedct = ct2
remotect = ct2
linkunkeyct = ct2
nounkeyct = 1
telemdefault = 2
telemdynamic = 1
lnkactenable = 0
rptena = 1
archivedir =

[events-${NODE_NUM}]

[morse]
speed = 20
frequency = 800
amplitude = 4096
idfrequency = 330
idamplitude = 2048

[${NODE_NUM}](node-main)
events = events-${NODE_NUM}
idrecording = |i${CALLSIGN}
duplex = 1
hangtime = 400
rxchannel = SimpleUSB/${NODE_NUM}
RPTEOF
ok "$L_RPT_OK"

# --- simpleusb.conf ---
info "$L_USB_INFO"
cat > /etc/asterisk/simpleusb.conf << USBEOF
[general]

[node-main](!)
eeprom = 0
hdwtype = 0
rxboost = yes
carrierfrom = usbinvert
ctcssfrom = usbinvert
deemphasis = no
plfilter = yes
rxondelay = 0
txoffdelay = 0
invertptt = no
preemphasis = no
clipledgpio = 1
legacyaudioscaling = no

[${NODE_NUM}](node-main)
devstr=
rxmixerset=${RXMIX}
txmixaset=${TXMIXA}
txmixbset=${TXMIXB}
USBEOF
ok "$L_USB_OK"

# --- rpt_http_registrations.conf ---
info "$L_REG_INFO"
cat > /etc/asterisk/rpt_http_registrations.conf << REGEOF
[general]
register_interval = 180

register => ${NODE_NUM}:${NODE_PASS}@register.allstarlink.org
REGEOF
ok "$L_REG_OK"

# --- extensions.conf ---
info "$L_EXT_INFO"
if grep -q "^NODE = " /etc/asterisk/extensions.conf 2>/dev/null; then
  sed -i "s/^NODE = .*/NODE = ${NODE_NUM}/" /etc/asterisk/extensions.conf
else
  sed -i "1s/^/NODE = ${NODE_NUM}\n/" /etc/asterisk/extensions.conf
fi
ok "$L_EXT_OK"

# --- manager.conf (AMI voor Allmon3) ---
info "$L_MGR_INFO"
AMI_PASS=$(openssl rand -base64 16 | tr -d '=+/' | head -c 20)
cat > /etc/asterisk/manager.conf << MGREOF
[general]
enabled = yes
port = 5038
bindaddr = 127.0.0.1

[admin]
secret = ${AMI_PASS}
read = system,call,log,verbose,agent,user,config,dtmf,reporting,cdr,dialplan
write = system,call,agent,user,config,command,reporting,originate,message
MGREOF
ok "$L_MGR_OK"

# =============================================================================
# STAP 5: SHARI SA818 CONFIGUREREN
# =============================================================================
step "$L_STEP5"

CTCSS_TX_VAL="${SA818_CTCSS_TX:-None}"
CTCSS_RX_VAL="${SA818_CTCSS_RX:-None}"

cat > /etc/sa818.conf << SA818EOF
CURRENT_BAND=UHF
CURRENT_BANDWIDTH=${SA818_BW}
CURRENT_FREQ_RX=${SA818_FREQ_RX}
CURRENT_FREQ_TX=${SA818_FREQ_TX}
CURRENT_SQUELCH=${SA818_SQ}
CURRENT_VOLUME=${SA818_VOL}
CURRENT_TONE=None
CURRENT_CTCSS_RX=${CTCSS_RX_VAL}
CURRENT_CTCSS_TX=${CTCSS_TX_VAL}
CURRENT_DCS_RX=None
CURRENT_DCS_TX=None
CURRENT_TAIL_TONE=Closed
CURRENT_EMPHASIS=Disabled
CURRENT_FILTER_HIGH_PASS=Disabled
CURRENT_FILTER_LOW_PASS=Disabled
CURRENT_PORT=
CURRENT_SPEED=
SA818EOF
ok "SA818 geconfigureerd (${SA818_FREQ_RX} MHz ${SA818_BW})"

if command -v shari-config &>/dev/null; then
  info "$L_SA818_PROG"
  shari-config 2>/dev/null && ok "$L_SA818_PROG_OK" || \
    warn "$L_SA818_PROG_WARN"
else
  warn "$L_SA818_NOTFOUND"
fi

# =============================================================================
# STAP 6: ALLMON3 INSTALLEREN
# =============================================================================
step "$L_STEP6"

apt-get install -y -q allmon3
ok "${L_AM3_INSTALLED} ($(dpkg -l allmon3 | tail -1 | awk '{print $3}'))"

a2enmod proxy proxy_http rewrite 2>/dev/null
ok "$L_APACHE_OK"

# =============================================================================
# STAP 7: ALLMON3 CONFIGUREREN
# =============================================================================
step "$L_STEP7"

mkdir -p /etc/allmon3

cat > /etc/allmon3/allmon3.ini << ALMEOF
[${NODE_NUM}]
host = 127.0.0.1
user = admin
pass = ${AMI_PASS}
ALMEOF
ok "allmon3.ini → node ${NODE_NUM}"

# =============================================================================
# STAP 8: ALLMON3 GEBRUIKER AANMAKEN
# =============================================================================
step "$L_STEP8"

SALT=$(openssl rand -base64 12 | tr -d '=+/')
HASH=$(echo -n "${WEB_PASS}" | argon2 "${SALT}" -id -t 3 -m 16 -p 4 -l 32 -e)
echo "${WEB_USER}|${HASH}" > /etc/allmon3/users
chmod 640 /etc/allmon3/users
chown www-data:www-data /etc/allmon3/users 2>/dev/null || true
ok "'${WEB_USER}' — ${L_STEP8}"

# =============================================================================
# STAP 9: SERVICES STARTEN
# =============================================================================
step "$L_STEP9"

a2enconf allmon3 2>/dev/null || warn "$L_APACHE_CONF_WARN"
a2dissite 000-default 2>/dev/null || true

systemctl daemon-reload
systemctl enable apache2 asterisk allmon3
systemctl start asterisk
systemctl restart allmon3
systemctl restart apache2
ok "$L_SERVICES_OK"

sleep 3

# =============================================================================
# AFSLUITING / FINISH
# =============================================================================
IP=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${BOLD}${GREEN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║${L_DONE_TITLE}                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${BOLD}${L_DONE_NODE}:${NC}   ${NODE_NUM} (${CALLSIGN})"
echo -e "  ${BOLD}${L_DONE_FREQ}:${NC}         ${SA818_FREQ_RX} MHz ${SA818_BW}"
echo -e "  ${BOLD}${L_DONE_WEB}:${NC}            http://${IP}/allmon3"
echo -e "  ${BOLD}${L_DONE_LOGIN}:${NC}              ${WEB_USER} / ${L_DONE_PASS_HINT}"
echo ""
read -p "$L_REBOOT_PROMPT"
reboot
