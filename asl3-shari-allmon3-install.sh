#!/bin/bash
# =============================================================================
# ASL3 + SHARI SA818 + Allmon3 Installatiescript
# =============================================================================
# Ondersteunde omgeving:
#   - Raspberry Pi OS 64-bit Lite (Debian Bookworm)
#   - SHARI SA818 USB interface (C-Media USB, ALSA)
#   - AllStarLink 3 (ASL3)
#   - Allmon3 webinterface (bereikbaar op http://IP/allmon3)
#
# Gebruik: sudo bash asl3-shari-allmon3-install.sh
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
warn() { echo -e "${YELLOW}[WAARSCHUWING]${NC} $1"; }
err()  { echo -e "${RED}[FOUT]${NC} $1"; exit 1; }
step() { echo -e "\n${BOLD}${CYAN}=== $1 ===${NC}"; }

# Root check
[ "$EUID" -ne 0 ] && err "Voer dit script uit als root: sudo bash $0"

# Whiptail check
command -v whiptail &>/dev/null || err "whiptail niet gevonden. Installeer met: apt install whiptail"

# OS check — ASL3 vereist Debian 12 Bookworm
CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
if [ "$CODENAME" != "bookworm" ]; then
  err "Dit script vereist Raspberry Pi OS / Debian 12 Bookworm. Gedetecteerd: ${CODENAME}"
fi
ok "OS: Debian ${CODENAME} — OK"

# =============================================================================
# STAP 1: CONFIGURATIE INVOER (whiptail)
# =============================================================================

WT_TITLE="ASL3 + SHARI SA818 + Allmon3 Installatie"

whiptail --title "$WT_TITLE" --msgbox \
"Dit script installeert en configureert:

  * AllStarLink 3 (ASL3)
  * SHARI SA818 USB interface
  * Allmon3 webinterface (http://IP/allmon3)

Druk Enter voor de standaardwaarde bij elk veld.
Druk Escape of Annuleren om te stoppen." \
14 64

# --- Systeemgegevens ---
RPI_USER=$(whiptail --title "$WT_TITLE" \
  --inputbox "RPi gebruikersnaam (Linux login op deze Pi):" \
  8 60 "pi" 3>&1 1>&2 2>&3) || { echo "Installatie geannuleerd."; exit 0; }
RPI_USER=${RPI_USER:-pi}

# --- AllStarLink gegevens ---
whiptail --title "$WT_TITLE" --msgbox \
"AllStarLink gegevens

Nodenummer en wachtwoord vind je op allstarlink.org
na inloggen onder: Portal > Node Settings." \
10 60

NODE_NUM=$(whiptail --title "$WT_TITLE" \
  --inputbox "Nodenummer (bijv. 44958):" \
  8 60 "" 3>&1 1>&2 2>&3) || { echo "Installatie geannuleerd."; exit 0; }
[ -z "$NODE_NUM" ] && err "Nodenummer is verplicht."

NODE_PASS=$(whiptail --title "$WT_TITLE" \
  --passwordbox "Node wachtwoord (van allstarlink.org portaal):" \
  8 60 3>&1 1>&2 2>&3) || { echo "Installatie geannuleerd."; exit 0; }
[ -z "$NODE_PASS" ] && err "Node wachtwoord is verplicht."

CALLSIGN=$(whiptail --title "$WT_TITLE" \
  --inputbox "Roepnaam (bijv. PE1BZF):" \
  8 60 "" 3>&1 1>&2 2>&3) || { echo "Installatie geannuleerd."; exit 0; }
[ -z "$CALLSIGN" ] && err "Roepnaam is verplicht."

# --- SA818 / Radio configuratie ---
SA818_FREQ_RX=$(whiptail --title "$WT_TITLE" \
  --inputbox "Frequentie RX (MHz):" \
  8 60 "430.5000" 3>&1 1>&2 2>&3) || { echo "Installatie geannuleerd."; exit 0; }
SA818_FREQ_RX=${SA818_FREQ_RX:-430.5000}

SA818_FREQ_TX=$(whiptail --title "$WT_TITLE" \
  --inputbox "Frequentie TX (MHz):" \
  8 60 "$SA818_FREQ_RX" 3>&1 1>&2 2>&3) || { echo "Installatie geannuleerd."; exit 0; }
SA818_FREQ_TX=${SA818_FREQ_TX:-$SA818_FREQ_RX}

SA818_BW=$(whiptail --title "$WT_TITLE" \
  --menu "Bandbreedte:" 12 64 2 \
  "Narrow" "Smalband (12.5 kHz) — standaard voor Nederland" \
  "Wide"   "Breedband (25 kHz)" \
  3>&1 1>&2 2>&3) || { echo "Installatie geannuleerd."; exit 0; }

SA818_SQ=$(whiptail --title "$WT_TITLE" \
  --inputbox "Squelch niveau (0-8):" \
  8 60 "1" 3>&1 1>&2 2>&3) || { echo "Installatie geannuleerd."; exit 0; }
SA818_SQ=${SA818_SQ:-1}

SA818_VOL=$(whiptail --title "$WT_TITLE" \
  --inputbox "SA818 volume (1-8):" \
  8 60 "1" 3>&1 1>&2 2>&3) || { echo "Installatie geannuleerd."; exit 0; }
SA818_VOL=${SA818_VOL:-1}

SA818_CTCSS_TX=$(whiptail --title "$WT_TITLE" \
  --inputbox "CTCSS toon TX (bijv. 88.5 — leeg = geen):" \
  8 60 "" 3>&1 1>&2 2>&3) || { echo "Installatie geannuleerd."; exit 0; }

SA818_CTCSS_RX=$(whiptail --title "$WT_TITLE" \
  --inputbox "CTCSS toon RX (bijv. 88.5 — leeg = geen):" \
  8 60 "" 3>&1 1>&2 2>&3) || { echo "Installatie geannuleerd."; exit 0; }

# --- Audio afstemming (SimpleUSB) ---
RXMIX=$(whiptail --title "$WT_TITLE" \
  --inputbox "RX mix niveau (0-999) — standaard voor SHARI SA818:" \
  8 60 "800" 3>&1 1>&2 2>&3) || { echo "Installatie geannuleerd."; exit 0; }
RXMIX=${RXMIX:-800}

TXMIXA=$(whiptail --title "$WT_TITLE" \
  --inputbox "TX mix A niveau (0-999):" \
  8 60 "600" 3>&1 1>&2 2>&3) || { echo "Installatie geannuleerd."; exit 0; }
TXMIXA=${TXMIXA:-600}

TXMIXB=$(whiptail --title "$WT_TITLE" \
  --inputbox "TX mix B niveau (0-999):" \
  8 60 "500" 3>&1 1>&2 2>&3) || { echo "Installatie geannuleerd."; exit 0; }
TXMIXB=${TXMIXB:-500}

# --- Allmon3 webinterface ---
WEB_USER=$(whiptail --title "$WT_TITLE" \
  --inputbox "Allmon3 gebruikersnaam:" \
  8 60 "admin" 3>&1 1>&2 2>&3) || { echo "Installatie geannuleerd."; exit 0; }
WEB_USER=${WEB_USER:-admin}

while true; do
  WEB_PASS=$(whiptail --title "$WT_TITLE" \
    --passwordbox "Allmon3 wachtwoord:" \
    8 60 3>&1 1>&2 2>&3) || { echo "Installatie geannuleerd."; exit 0; }
  if [ -z "$WEB_PASS" ]; then
    whiptail --title "$WT_TITLE" --msgbox "Wachtwoord is verplicht." 8 40
    continue
  fi
  WEB_PASS2=$(whiptail --title "$WT_TITLE" \
    --passwordbox "Bevestig wachtwoord:" \
    8 60 3>&1 1>&2 2>&3) || { echo "Installatie geannuleerd."; exit 0; }
  [ "$WEB_PASS" = "$WEB_PASS2" ] && break
  whiptail --title "$WT_TITLE" --msgbox "Wachtwoorden komen niet overeen. Probeer opnieuw." 8 52
done

# --- Samenvatting ---
CTCSS_TX_DISP="${SA818_CTCSS_TX:-geen}"
CTCSS_RX_DISP="${SA818_CTCSS_RX:-geen}"

whiptail --title "$WT_TITLE — Samenvatting" --yesno \
"Controleer de instellingen voor installatie:

  Systeem gebruiker   : ${RPI_USER}
  Node nummer         : ${NODE_NUM}
  Node wachtwoord     : ****
  Roepnaam            : ${CALLSIGN}
  Frequentie RX/TX    : ${SA818_FREQ_RX} / ${SA818_FREQ_TX} MHz
  Bandbreedte         : ${SA818_BW}
  Squelch             : ${SA818_SQ}
  SA818 volume        : ${SA818_VOL}
  CTCSS TX/RX         : ${CTCSS_TX_DISP} / ${CTCSS_RX_DISP}
  RX/TXA/TXB mix      : ${RXMIX} / ${TXMIXA} / ${TXMIXB}
  Allmon3 gebruiker   : ${WEB_USER}

Doorgaan met installatie?" \
22 66 || { echo "Installatie geannuleerd."; exit 0; }

# =============================================================================
# STAP 2: SYSTEEM VOORBEREIDING
# =============================================================================
step "Systeem bijwerken en dependencies installeren"

apt-get update -q
apt-get upgrade -y -q
apt-get install -y -q \
  curl wget ca-certificates gnupg \
  apache2 argon2
ok "Systeem bijgewerkt"

# =============================================================================
# STAP 3: ASL3 INSTALLATIE
# =============================================================================
step "AllStarLink 3 (ASL3) installeren"

if ! dpkg -l asl3 &>/dev/null; then
  info "ASL3 apt repository toevoegen..."
  ASL_REPO_URL="https://repo.allstarlink.org/public/asl-apt-repos.deb12_all.deb"
  curl -fsSL "$ASL_REPO_URL" -o /tmp/asl-apt-repos.deb || \
    err "Kon ASL3 repo pakket niet downloaden."
  dpkg -i /tmp/asl-apt-repos.deb
  apt-get update -q

  info "Kernel headers installeren (vereist voor dahdi-dkms)..."
  apt-get install -y -q raspberrypi-kernel-headers || \
    apt-get install -y -q linux-headers-$(uname -r) || \
    warn "Kernel headers niet gevonden — dahdi-dkms compilatie kan mislukken"

  apt-get install -y -q asl3 || \
    err "ASL3 installatie mislukt. Voer 'apt-get install -y asl3' handmatig uit voor meer details."
  ok "ASL3 geïnstalleerd ($(dpkg -l asl3 | tail -1 | awk '{print $3}'))"
else
  ok "ASL3 is al geïnstalleerd ($(dpkg -l asl3 | tail -1 | awk '{print $3}'))"
fi

# ASL3 stoppen voor configuratie
systemctl stop asterisk 2>/dev/null || true

# =============================================================================
# STAP 4: ASL3 CONFIGURATIE
# =============================================================================
step "ASL3 configureren"

# --- rpt.conf ---
info "rpt.conf configureren..."
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
ok "rpt.conf geschreven"

# --- simpleusb.conf ---
info "simpleusb.conf configureren..."
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

[${NODE_NUM}](node-main,shari-pixx)
devstr=
rxmixerset=${RXMIX}
txmixaset=${TXMIXA}
txmixbset=${TXMIXB}
USBEOF
ok "simpleusb.conf geschreven"

# --- rpt_http_registrations.conf ---
info "Node registratie configureren..."
cat > /etc/asterisk/rpt_http_registrations.conf << REGEOF
[general]
register_interval = 180

register => ${NODE_NUM}:${NODE_PASS}@register.allstarlink.org
REGEOF
ok "Registratie geconfigureerd"

# --- extensions.conf ---
info "extensions.conf bijwerken..."
if grep -q "^NODE = " /etc/asterisk/extensions.conf 2>/dev/null; then
  sed -i "s/^NODE = .*/NODE = ${NODE_NUM}/" /etc/asterisk/extensions.conf
else
  sed -i "1s/^/NODE = ${NODE_NUM}\n/" /etc/asterisk/extensions.conf
fi
ok "extensions.conf bijgewerkt"

# --- manager.conf (AMI voor Allmon3) ---
info "manager.conf configureren..."
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
ok "manager.conf geschreven"

# =============================================================================
# STAP 5: SHARI SA818 CONFIGUREREN
# =============================================================================
step "SHARI SA818 configureren"

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
  info "SA818 programmeren via shari-config..."
  shari-config 2>/dev/null && ok "SA818 geprogrammeerd" || \
    warn "SA818 programmeren mislukt — handmatig uitvoeren: sudo shari-config"
else
  warn "shari-config niet gevonden — SA818 wordt bij eerste reboot geconfigureerd"
fi

# =============================================================================
# STAP 6: ALLMON3 INSTALLEREN
# =============================================================================
step "Allmon3 installeren"

apt-get install -y -q allmon3
ok "Allmon3 geïnstalleerd ($(dpkg -l allmon3 | tail -1 | awk '{print $3}'))"

a2enmod proxy proxy_http rewrite 2>/dev/null
ok "Apache modules ingeschakeld"

# =============================================================================
# STAP 7: ALLMON3 CONFIGUREREN
# =============================================================================
step "Allmon3 configureren"

mkdir -p /etc/allmon3

cat > /etc/allmon3/allmon3.ini << ALMEOF
[${NODE_NUM}]
host = 127.0.0.1
user = admin
pass = ${AMI_PASS}
ALMEOF
ok "allmon3.ini geschreven (node ${NODE_NUM})"

# =============================================================================
# STAP 8: ALLMON3 GEBRUIKER AANMAKEN
# =============================================================================
step "Allmon3 gebruiker aanmaken"

SALT=$(openssl rand -base64 12 | tr -d '=+/')
HASH=$(echo -n "${WEB_PASS}" | argon2 "${SALT}" -id -t 3 -m 65536 -p 4 -l 32 -e)
echo "${WEB_USER}|${HASH}" > /etc/allmon3/users
chmod 640 /etc/allmon3/users
chown www-data:www-data /etc/allmon3/users 2>/dev/null || true
ok "Gebruiker '${WEB_USER}' aangemaakt"

# =============================================================================
# STAP 9: SERVICES STARTEN
# =============================================================================
step "Alle services starten"

a2enconf allmon3 2>/dev/null || warn "Allmon3 Apache conf niet gevonden via a2enconf"
a2dissite 000-default 2>/dev/null || true

systemctl daemon-reload
systemctl enable apache2 asterisk allmon3
systemctl start asterisk
systemctl restart allmon3
systemctl restart apache2
ok "Alle services gestart"

sleep 3

# =============================================================================
# AFSLUITING
# =============================================================================
IP=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${BOLD}${GREEN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  INSTALLATIE VOLTOOID!                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${BOLD}AllStarLink node:${NC}   ${NODE_NUM} (${CALLSIGN})"
echo -e "  ${BOLD}Frequentie:${NC}         ${SA818_FREQ_RX} MHz ${SA818_BW}"
echo -e "  ${BOLD}Allmon3:${NC}            http://${IP}/allmon3"
echo -e "  ${BOLD}Login:${NC}              ${WEB_USER} / [jouw wachtwoord]"
echo ""
read -p "Druk Enter om te herstarten (of Ctrl+C om te annuleren)... "
reboot
