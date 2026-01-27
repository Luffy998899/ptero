#!/bin/bash

set -e

######################################################################################
#                                                                                    #
#  Pterodactyl Wings - Quick Installer                                              #
#                                                                                    #
######################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           🐦 PTERODACTYL WINGS INSTALLER 🐦                  ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root!${NC}"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}Cannot detect OS${NC}"
    exit 1
fi

echo -e "${BLUE}Detected OS:${NC} $OS"

# Install Docker
echo -e "${CYAN}[1/4] Installing Docker...${NC}"

if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | bash
    systemctl enable --now docker
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi

# Install Wings
echo -e "${CYAN}[2/4] Installing Wings...${NC}"

mkdir -p /etc/pterodactyl
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
chmod u+x /usr/local/bin/wings

echo -e "${GREEN}✓ Wings installed${NC}"

# Create service
echo -e "${CYAN}[3/4] Creating systemd service...${NC}"

cat > /etc/systemd/system/wings.service <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

echo -e "${GREEN}✓ Service created${NC}"

# Instructions
echo -e "${CYAN}[4/4] Configuration needed...${NC}"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}           WINGS INSTALLED SUCCESSFULLY! 🎉                     ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo -e "1. Go to your Panel → Admin → Nodes"
echo -e "2. Create a new node or select existing"
echo -e "3. Go to 'Configuration' tab"
echo -e "4. Copy the configuration and save to:"
echo -e "   ${CYAN}/etc/pterodactyl/config.yml${NC}"
echo ""
echo -e "5. Start Wings:"
echo -e "   ${CYAN}systemctl enable --now wings${NC}"
echo ""
echo -e "6. Check status:"
echo -e "   ${CYAN}systemctl status wings${NC}"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
