#!/bin/bash
# =============================================================================
# ASL3 + SHARI SA818 (optioneel) + Allmon3 Installatiescript
# ASL3 + SHARI SA818 (optional)  + Allmon3 Installation Script
# =============================================================================
# Ondersteunde omgeving / Supported environment:
#   - Raspberry Pi OS 64-bit Lite (Debian Bookworm)
#   - SHARI SA818 USB interface (C-Media USB, ALSA) — optioneel / optional
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

  WT_TITLE="ASL3 + Allmon3 Installation"

  L_WELCOME="This script installs and configures:

  * AllStarLink 3 (ASL3)
  * SHARI SA818 USB interface (optional)
  * Allmon3 web interface (http://IP/allmon3)

Press Enter for the default value in each field.
Press Escape or Cancel to abort."

  L_SHARI_PROMPT="Is a SHARI SA818 USB radio interface connected?

Choose Yes for the SHARI SA818 USB module (C-Media CM108).
Choose No for other USB audio interfaces — SA818 programming
and radio settings will be skipped."

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
  L_HUB_PROMPT="Hub node number (optional — auto-connect on startup):

Leave empty for no automatic connection."
  L_WEBUSER_PROMPT="Allmon3 username:"
  L_WEBPASS_PROMPT="Allmon3 password:"
  L_WEBPASS_ERR="Password is required."
  L_WEBPASS2_PROMPT="Confirm password:"
  L_WEBPASS_MISMATCH="Passwords do not match. Please try again."

  L_SUMMARY_TITLE="ASL3 + Allmon3 Installation — Summary"
  L_SUMMARY_INTRO="Review the settings before installation:"
  L_SUMMARY_USER="System user        "
  L_SUMMARY_NODE="Node number        "
  L_SUMMARY_PASS="Node password      "
  L_SUMMARY_CALL="Callsign           "
  L_SUMMARY_SHARI="SHARI SA818        "
  L_SUMMARY_FREQ="Frequency RX/TX    "
  L_SUMMARY_BW="Bandwidth          "
  L_SUMMARY_SQ="Squelch            "
  L_SUMMARY_VOL="SA818 volume       "
  L_SUMMARY_CTCSS="CTCSS TX/RX        "
  L_SUMMARY_MIX="RX/TXA/TXB mix     "
  L_SUMMARY_HUB="Hub node           "
  L_SUMMARY_WEBUSER="Allmon3 user       "
  L_SUMMARY_CONFIRM="Proceed with installation?"
  L_CTCSS_NONE="none"
  L_HUB_NONE="none"
  L_SHARI_YES="Yes"
  L_SHARI_NO="No"

  L_STEP2="Update system and install dependencies"
  L_STEP3="Install AllStarLink 3 (ASL3)"
  L_STEP4="Configure ASL3"
  L_STEP5="Configure SHARI SA818"
  L_STEP5_SKIP="Skipping SHARI SA818 (no SHARI selected)"
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
  L_IAX_INFO="Configuring iax.conf..."
  L_IAX_OK="iax.conf updated"
  L_MGR_INFO="Configuring manager.conf..."
  L_MGR_OK="manager.conf written"
  L_ALSA_FIX_OK="config.txt: vc4-kms-v3d,noaudio set (prevents HDMI from stealing ALSA card slot)"
  L_ALSA_FIX_SKIP="config.txt: vc4-kms-v3d,noaudio already set"
  L_SA818_PROG="Programming SA818 via serial port..."
  L_SA818_PROG_OK="SA818 programmed"
  L_SA818_PROG_WARN="SA818 programming failed — check serial port /dev/ttyUSB0"
  L_SA818_NOTFOUND="No serial port found — connect SA818 and run: sudo python3 /usr/local/sbin/sa818-prog.py"
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

  WT_TITLE="ASL3 + Allmon3 Installatie"

  L_WELCOME="Dit script installeert en configureert:

  * AllStarLink 3 (ASL3)
  * SHARI SA818 USB interface (optioneel)
  * Allmon3 webinterface (http://IP/allmon3)

Druk Enter voor de standaardwaarde bij elk veld.
Druk Escape of Annuleren om te stoppen."

  L_SHARI_PROMPT="Is er een SHARI SA818 USB radio interface aangesloten?

Kies Ja voor de SHARI SA818 USB module (C-Media CM108).
Kies Nee voor andere USB audio interfaces — SA818 programmering
en radio-instellingen worden dan overgeslagen."

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
  L_HUB_PROMPT="Hub node nummer (optioneel — automatisch verbinden bij opstarten):

Leeg laten voor geen automatische verbinding."
  L_WEBUSER_PROMPT="Allmon3 gebruikersnaam:"
  L_WEBPASS_PROMPT="Allmon3 wachtwoord:"
  L_WEBPASS_ERR="Wachtwoord is verplicht."
  L_WEBPASS2_PROMPT="Bevestig wachtwoord:"
  L_WEBPASS_MISMATCH="Wachtwoorden komen niet overeen. Probeer opnieuw."

  L_SUMMARY_TITLE="ASL3 + Allmon3 Installatie — Samenvatting"
  L_SUMMARY_INTRO="Controleer de instellingen voor installatie:"
  L_SUMMARY_USER="Systeem gebruiker  "
  L_SUMMARY_NODE="Node nummer        "
  L_SUMMARY_PASS="Node wachtwoord    "
  L_SUMMARY_CALL="Roepnaam           "
  L_SUMMARY_SHARI="SHARI SA818        "
  L_SUMMARY_FREQ="Frequentie RX/TX   "
  L_SUMMARY_BW="Bandbreedte        "
  L_SUMMARY_SQ="Squelch            "
  L_SUMMARY_VOL="SA818 volume       "
  L_SUMMARY_CTCSS="CTCSS TX/RX        "
  L_SUMMARY_MIX="RX/TXA/TXB mix     "
  L_SUMMARY_HUB="Hub node           "
  L_SUMMARY_WEBUSER="Allmon3 gebruiker  "
  L_SUMMARY_CONFIRM="Doorgaan met installatie?"
  L_CTCSS_NONE="geen"
  L_HUB_NONE="geen"
  L_SHARI_YES="Ja"
  L_SHARI_NO="Nee"

  L_STEP2="Systeem bijwerken en dependencies installeren"
  L_STEP3="AllStarLink 3 (ASL3) installeren"
  L_STEP4="ASL3 configureren"
  L_STEP5="SHARI SA818 configureren"
  L_STEP5_SKIP="SHARI SA818 overgeslagen (geen SHARI geselecteerd)"
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
  L_IAX_INFO="iax.conf configureren..."
  L_IAX_OK="iax.conf bijgewerkt"
  L_MGR_INFO="manager.conf configureren..."
  L_MGR_OK="manager.conf geschreven"
  L_ALSA_FIX_OK="config.txt: vc4-kms-v3d,noaudio ingesteld (voorkomt dat HDMI ALSA card-slot inneemt)"
  L_ALSA_FIX_SKIP="config.txt: vc4-kms-v3d,noaudio al aanwezig"
  L_SA818_PROG="SA818 programmeren via seriële poort..."
  L_SA818_PROG_OK="SA818 geprogrammeerd"
  L_SA818_PROG_WARN="SA818 programmeren mislukt — controleer seriële poort /dev/ttyUSB0"
  L_SA818_NOTFOUND="Geen seriële poort gevonden — sluit SA818 aan en herstart het script"
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

whiptail --title "$WT_TITLE" --msgbox "$L_WELCOME" 16 64

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

# --- SHARI SA818 keuze ---
if whiptail --title "$WT_TITLE" --yesno "$L_SHARI_PROMPT" 14 66; then
  USE_SHARI=yes
else
  USE_SHARI=no
fi

# --- SA818 / Radio configuratie (alleen bij SHARI) ---
if [ "$USE_SHARI" = "yes" ]; then
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
    8 60 "8" 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }
  SA818_VOL=${SA818_VOL:-8}

  SA818_CTCSS_TX=$(whiptail --title "$WT_TITLE" \
    --inputbox "$L_CTCSS_TX_PROMPT" \
    8 60 "" 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }

  SA818_CTCSS_RX=$(whiptail --title "$WT_TITLE" \
    --inputbox "$L_CTCSS_RX_PROMPT" \
    8 60 "" 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }
fi

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

# --- Hub node (optioneel) ---
HUB_NODE=$(whiptail --title "$WT_TITLE" \
  --inputbox "$L_HUB_PROMPT" \
  10 60 "" 3>&1 1>&2 2>&3) || { echo "$L_CANCELLED"; exit 0; }

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
HUB_DISP="${HUB_NODE:-$L_HUB_NONE}"
SHARI_DISP="$( [ "$USE_SHARI" = "yes" ] && echo "$L_SHARI_YES" || echo "$L_SHARI_NO" )"

# Bouw samenvatting op afhankelijk van SHARI keuze
if [ "$USE_SHARI" = "yes" ]; then
  SHARI_SUMMARY="  ${L_SUMMARY_FREQ}: ${SA818_FREQ_RX} / ${SA818_FREQ_TX} MHz
  ${L_SUMMARY_BW}: ${SA818_BW}
  ${L_SUMMARY_SQ}: ${SA818_SQ}
  ${L_SUMMARY_VOL}: ${SA818_VOL}
  ${L_SUMMARY_CTCSS}: ${CTCSS_TX_DISP} / ${CTCSS_RX_DISP}"
else
  SHARI_SUMMARY=""
fi

whiptail --title "$L_SUMMARY_TITLE" --yesno \
"${L_SUMMARY_INTRO}

  ${L_SUMMARY_USER}: ${RPI_USER}
  ${L_SUMMARY_NODE}: ${NODE_NUM}
  ${L_SUMMARY_PASS}: ****
  ${L_SUMMARY_CALL}: ${CALLSIGN}
  ${L_SUMMARY_SHARI}: ${SHARI_DISP}
${SHARI_SUMMARY}
  ${L_SUMMARY_MIX}: ${RXMIX} / ${TXMIXA} / ${TXMIXB}
  ${L_SUMMARY_HUB}: ${HUB_DISP}
  ${L_SUMMARY_WEBUSER}: ${WEB_USER}

${L_SUMMARY_CONFIRM}" \
26 66 || { echo "$L_CANCELLED"; exit 0; }

# =============================================================================
# STAP 2: SYSTEEM VOORBEREIDING
# =============================================================================
step "$L_STEP2"

apt-get update -q
apt-get upgrade -y -q
apt-get install -y -q \
  curl wget ca-certificates gnupg \
  apache2 python3-serial
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

# Bepaal events sectie (SHARI heeft GPIO4 PTT LED events)
if [ "$USE_SHARI" = "yes" ]; then
  EVENTS_SECTION="[events-${NODE_NUM}]
cop,62,GPIO4:1 = c|t|RPT_RXKEYED
cop,62,GPIO4:0 = c|f|RPT_RXKEYED"
else
  EVENTS_SECTION="[events-${NODE_NUM}]"
fi

# Bepaal startup_macro (hub node auto-connect)
if [ -n "$HUB_NODE" ]; then
  STARTUP_MACRO="startup_macro = *3${HUB_NODE}"
else
  STARTUP_MACRO=""
fi

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
functions = functions
link_functions = functions
phone_functions = functions
morse = morse
telemetry = telemetry
scheduler = schedule
wait_times = wait-times

[functions]
1 = ilink,1
2 = ilink,2
3 = ilink,3
4 = ilink,4
70 = ilink,5
99 = cop,6
5 = macro
721 = status,1
722 = status,2
723 = status,3
711 = status,11
712 = status,12

[wait-times]
telemwait = 1000
voicetellockout = 1000
remotetx = 1000
remotemon = 1000

${EVENTS_SECTION}

[morse]
speed = 20
frequency = 800
amplitude = 4096
idfrequency = 330
idamplitude = 2048

[${NODE_NUM}](node-main)
events = events-${NODE_NUM}
rxchannel = SimpleUSB/${NODE_NUM}
${STARTUP_MACRO}
RPTEOF
ok "$L_RPT_OK"

# --- simpleusb.conf ---
info "$L_USB_INFO"
cat > /etc/asterisk/simpleusb.conf << USBEOF
[general]

[node-main](!)
eeprom = 0
hdwtype = 0
rxboost = no
carrierfrom = usbinvert
ctcssfrom = no
deemphasis = no
plfilter = no
rxondelay = 0
txoffdelay = 0
invertptt = no
preemphasis = no
clipledgpio = 1
legacyaudioscaling = no
txmixa = voice
txmixb = no

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

# --- extensions.conf: NODE in [globals] sectie ---
info "$L_EXT_INFO"
if grep -q "^\[globals\]" /etc/asterisk/extensions.conf 2>/dev/null; then
  # Verwijder bestaande NODE regel (waar ook in het bestand)
  sed -i "/^NODE = /d" /etc/asterisk/extensions.conf
  # Voeg NODE in direct na [globals]
  sed -i "/^\[globals\]/a NODE = ${NODE_NUM}" /etc/asterisk/extensions.conf
else
  # Geen [globals] sectie — voeg toe na [general] blok
  sed -i "/^writeprotect/a \\\n[globals]\nNODE = ${NODE_NUM}" /etc/asterisk/extensions.conf
fi
ok "$L_EXT_OK"

# --- iax.conf: IAX2 registratie voor AllStar DNS ---
info "$L_IAX_INFO"
if grep -q "^register => ${NODE_NUM}:" /etc/asterisk/iax.conf 2>/dev/null; then
  sed -i "s|^register => ${NODE_NUM}:.*|register => ${NODE_NUM}:${NODE_PASS}@register.allstarlink.org|" \
    /etc/asterisk/iax.conf
else
  sed -i "/^\[general\]/a register => ${NODE_NUM}:${NODE_PASS}@register.allstarlink.org" \
    /etc/asterisk/iax.conf
fi
ok "$L_IAX_OK"

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
# STAP 5: SHARI SA818 CONFIGUREREN (alleen bij USE_SHARI=yes)
# =============================================================================
step "$L_STEP5"

if [ "$USE_SHARI" = "yes" ]; then

  # ALSA fix: voorkom dat vc4-kms-v3d HDMI audio ALSA card-slot inneemt
  CONFIG_TXT="/boot/firmware/config.txt"
  if [ -f "$CONFIG_TXT" ] && grep -q "dtoverlay=vc4-kms-v3d" "$CONFIG_TXT"; then
    if grep -q "dtoverlay=vc4-kms-v3d.*noaudio" "$CONFIG_TXT"; then
      ok "$L_ALSA_FIX_SKIP"
    else
      sed -i 's/dtoverlay=vc4-kms-v3d/dtoverlay=vc4-kms-v3d,noaudio/' "$CONFIG_TXT"
      ok "$L_ALSA_FIX_OK"
    fi
  fi

  CTCSS_TX_VAL="${SA818_CTCSS_TX:-None}"
  CTCSS_RX_VAL="${SA818_CTCSS_RX:-None}"

  if [ -n "$SA818_CTCSS_TX" ]; then
    SA818_TONE_MODE="CTCSS"
  else
    SA818_TONE_MODE="None"
  fi

  cat > /etc/sa818.conf << SA818EOF
CURRENT_BAND=UHF
CURRENT_BANDWIDTH=${SA818_BW}
CURRENT_FREQ_RX=${SA818_FREQ_RX}
CURRENT_FREQ_TX=${SA818_FREQ_TX}
CURRENT_SQUELCH=${SA818_SQ}
CURRENT_VOLUME=${SA818_VOL}
CURRENT_TONE=${SA818_TONE_MODE}
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

  # SA818 programmeren via Python/serial
  SA818_PORT=$(ls /dev/ttyUSB0 /dev/ttyAMA0 2>/dev/null | head -1)
  if [ -n "$SA818_PORT" ]; then
    info "$L_SA818_PROG"
    SA818_BW_CODE=0
    [ "$SA818_BW" = "Wide" ] && SA818_BW_CODE=1

    CTCSS_TABLE="0,67.0,71.9,74.4,77.0,79.7,82.5,85.4,88.5,91.5,94.8,97.4,100.0,103.5,107.2,110.9,114.8,118.8,123.0,127.3,131.8,136.5,141.3,146.2,151.4,156.7,162.2,167.9,173.8,179.9,186.2,192.8,203.5,210.7,218.1,225.7,233.6,241.8,250.3"
    CTCSS_TX_CODE=$(python3 -c "
t='${SA818_CTCSS_TX}'
tbl='${CTCSS_TABLE}'.split(',')
try:
    idx=tbl.index(t)
    print(f'{idx:04d}')
except:
    print('0000')
" 2>/dev/null)
    CTCSS_RX_CODE=$(python3 -c "
t='${SA818_CTCSS_RX}'
tbl='${CTCSS_TABLE}'.split(',')
try:
    idx=tbl.index(t)
    print(f'{idx:04d}')
except:
    print('0000')
" 2>/dev/null)

    python3 << PYEOF && ok "$L_SA818_PROG_OK" || warn "$L_SA818_PROG_WARN"
import serial, time
with serial.Serial('${SA818_PORT}', 9600, timeout=1) as s:
    time.sleep(0.3)
    def cmd(c):
        s.write((c+'\r\n').encode()); time.sleep(0.5); return s.read_all().decode(errors='ignore')
    cmd('AT+DMOCONNECT')
    r = cmd('AT+DMOSETGROUP=${SA818_BW_CODE},${SA818_FREQ_TX},${SA818_FREQ_RX},${CTCSS_TX_CODE},${SA818_SQ},${CTCSS_RX_CODE}')
    cmd('AT+DMOSETVOLUME=${SA818_VOL}')
    if '+DMOSETGROUP:0' not in r: raise Exception('SA818 niet bereikbaar')
PYEOF
  else
    warn "$L_SA818_NOTFOUND"
  fi

else
  info "$L_STEP5_SKIP"
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

allmon3-passwd "${WEB_USER}" --password "${WEB_PASS}"
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
if [ "$USE_SHARI" = "yes" ]; then
  echo -e "  ${BOLD}${L_DONE_FREQ}:${NC}         ${SA818_FREQ_RX} MHz ${SA818_BW}"
fi
if [ -n "$HUB_NODE" ]; then
  echo -e "  ${BOLD}Hub node:${NC}            ${HUB_NODE}"
fi
echo -e "  ${BOLD}${L_DONE_WEB}:${NC}            http://${IP}/allmon3"
echo -e "  ${BOLD}${L_DONE_LOGIN}:${NC}              ${WEB_USER} / ${L_DONE_PASS_HINT}"
echo ""
read -p "$L_REBOOT_PROMPT"
reboot
