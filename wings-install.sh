#!/bin/bash

set -e

# Error handler
trap 'echo -e "${RED}Error occurred on line $LINENO. Installation failed!${NC}"; exit 1' ERR

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
    echo -e "${BLUE}Downloading Docker installer...${NC}"
    if curl -fsSL https://get.docker.com | bash; then
        systemctl enable --now docker || { echo -e "${RED}Error: Failed to enable docker${NC}"; exit 1; }
        echo -e "${GREEN}✓ Docker installed${NC}"
    else
        echo -e "${RED}Error: Failed to install Docker${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi

# Verify Docker is running
if ! systemctl is-active --quiet docker; then
    echo -e "${RED}Error: Docker is not running${NC}"
    systemctl start docker || { echo -e "${RED}Error: Failed to start docker${NC}"; exit 1; }
fi

# Install Wings
echo -e "${CYAN}[2/4] Installing Wings...${NC}"

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
    WINGS_ARCH="amd64"
elif [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "arm64" ]; then
    WINGS_ARCH="arm64"
else
    echo -e "${RED}Error: Unsupported architecture: $ARCH${NC}"
    exit 1
fi

mkdir -p /etc/pterodactyl || { echo -e "${RED}Error: Failed to create pterodactyl directory${NC}"; exit 1; }

# Download Wings with retry
echo -e "${BLUE}Downloading Wings for $WINGS_ARCH...${NC}"
retry_count=0
max_retries=3
WINGS_URL="https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_${WINGS_ARCH}"

while [ $retry_count -lt $max_retries ]; do
    if curl -L -o /usr/local/bin/wings "$WINGS_URL"; then
        break
    fi
    retry_count=$((retry_count + 1))
    if [ $retry_count -lt $max_retries ]; then
        echo -e "${YELLOW}Download failed, retrying... ($retry_count/$max_retries)${NC}"
        sleep 5
    fi
done

if [ $retry_count -eq $max_retries ]; then
    echo -e "${RED}Error: Failed to download Wings after $max_retries attempts${NC}"
    exit 1
fi

# Verify the binary
if [ ! -f /usr/local/bin/wings ]; then
    echo -e "${RED}Error: Wings binary not found after download${NC}"
    exit 1
fi

# Check if it's an executable
if ! file /usr/local/bin/wings | grep -q "executable"; then
    echo -e "${RED}Error: Downloaded Wings is not a valid executable${NC}"
    rm -f /usr/local/bin/wings
    exit 1
fi

chmod u+x /usr/local/bin/wings || { echo -e "${RED}Error: Failed to make Wings executable${NC}"; exit 1; }

echo -e "${GREEN}✓ Wings installed${NC}"

# Create service
echo -e "${CYAN}[3/4] Creating systemd service...${NC}"

cat > /etc/systemd/system/wings.service <<EOF || { echo -e "${RED}Error: Failed to create wings service file${NC}"; exit 1; }
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

systemctl daemon-reload || { echo -e "${RED}Error: Failed to reload systemd${NC}"; exit 1; }

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
