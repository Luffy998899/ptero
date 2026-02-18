#!/bin/bash

set -e

# Error handler
trap 'echo -e "${RED}Error occurred on line $LINENO. Installation failed!${NC}"; exit 1' ERR

######################################################################################
#                                                                                    #
#  Pterodactyl Addons Panel - Installer                                             #
#                                                                                    #
#  This script installs a fully customized Pterodactyl Panel with:                  #
#  - All game addons (Minecraft, Rust, CS2, FiveM, ARK, GMod, Valheim, 7Days)      #
#  - All admin addons (Billing, Subdomains, Resource Upgrades, etc.)               #
#  - Premium themes (Neon Gaming, Eltahost)                                         #
#                                                                                    #
#  Made with ❤️ by elta.one (EltaGamingHost) - Given away for FREE!                 #
#                                                                                    #
######################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Variables
GITHUB_URL="https://github.com/MuLTiAcidi/pterodactyl-addons"
PANEL_VERSION="1.0.0"
INSTALL_DIR="/var/www/pterodactyl"

# Print banner
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                               ║"
    echo "║    ██████╗ ████████╗███████╗██████╗  ██████╗ ██████╗  █████╗  ██████╗████████╗║"
    echo "║    ██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██╔════╝╚══██╔══╝║"
    echo "║    ██████╔╝   ██║   █████╗  ██████╔╝██║   ██║██║  ██║███████║██║        ██║   ║"
    echo "║    ██╔═══╝    ██║   ██╔══╝  ██╔══██╗██║   ██║██║  ██║██╔══██║██║        ██║   ║"
    echo "║    ██║        ██║   ███████╗██║  ██║╚██████╔╝██████╔╝██║  ██║╚██████╗   ██║   ║"
    echo "║    ╚═╝        ╚═╝   ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝   ╚═╝   ║"
    echo "║                                                                               ║"
    echo "║                    🎮 ADDONS PANEL INSTALLER v${PANEL_VERSION} 🎮                        ║"
    echo "║                                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${WHITE}This installer will set up a complete Pterodactyl Panel with:${NC}"
    echo -e "${GREEN}  ✓ Game Addons:${NC} Minecraft, Rust, CS2, FiveM, ARK, GMod, Valheim, 7Days"
    echo -e "${GREEN}  ✓ Admin Addons:${NC} Billing, Subdomains, Resource Upgrades, Audit Log, etc."
    echo -e "${GREEN}  ✓ Themes:${NC} Neon Gaming, Eltahost Premium"
    echo ""
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root!${NC}"
        echo "Please run: sudo bash install.sh"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        echo -e "${RED}Error: Cannot detect operating system!${NC}"
        exit 1
    fi

    echo -e "${BLUE}Detected OS:${NC} $OS $OS_VERSION"

    case $OS in
        ubuntu)
            if [[ "$OS_VERSION" != "20.04" && "$OS_VERSION" != "22.04" && "$OS_VERSION" != "24.04" ]]; then
                echo -e "${YELLOW}Warning: Recommended Ubuntu versions are 20.04, 22.04, or 24.04${NC}"
            fi
            ;;
        debian)
            if [[ "$OS_VERSION" != "11" && "$OS_VERSION" != "12" ]]; then
                echo -e "${YELLOW}Warning: Recommended Debian versions are 11 or 12${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Error: Unsupported operating system: $OS${NC}"
            echo "Supported: Ubuntu 20.04/22.04/24.04, Debian 11/12"
            exit 1
            ;;
    esac
}

# Get user input
get_user_input() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                    CONFIGURATION                              ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Domain/FQDN
    echo -e "${YELLOW}Enter your panel domain (e.g., panel.example.com):${NC}"
    read -p "> " FQDN
    while [[ -z "$FQDN" ]]; do
        echo -e "${RED}Domain cannot be empty!${NC}"
        read -p "> " FQDN
    done

    # Panel Name
    echo ""
    echo -e "${YELLOW}Enter your panel name (e.g., My Game Hosting):${NC}"
    read -p "> " PANEL_NAME
    PANEL_NAME=${PANEL_NAME:-"Pterodactyl Panel"}

    # Admin Email
    echo ""
    echo -e "${YELLOW}Enter admin email:${NC}"
    read -p "> " ADMIN_EMAIL
    while [[ -z "$ADMIN_EMAIL" ]]; do
        echo -e "${RED}Admin email cannot be empty!${NC}"
        read -p "> " ADMIN_EMAIL
    done

    # Admin Username
    echo ""
    echo -e "${YELLOW}Enter admin username:${NC}"
    read -p "> " ADMIN_USER
    ADMIN_USER=${ADMIN_USER:-"admin"}

    # Admin Password
    echo ""
    echo -e "${YELLOW}Enter admin password (min 8 characters):${NC}"
    read -s -p "> " ADMIN_PASS
    echo ""
    while [[ ${#ADMIN_PASS} -lt 8 ]]; do
        echo -e "${RED}Password must be at least 8 characters!${NC}"
        read -s -p "> " ADMIN_PASS
        echo ""
    done

    # Database Password
    echo ""
    echo -e "${YELLOW}Enter MySQL/MariaDB root password:${NC}"
    read -s -p "> " DB_ROOT_PASS
    echo ""
    while [[ -z "$DB_ROOT_PASS" ]]; do
        echo -e "${RED}Database password cannot be empty!${NC}"
        read -s -p "> " DB_ROOT_PASS
        echo ""
    done

    # Generate random database password for panel
    DB_PASS=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)

    # SSL
    echo ""
    echo -e "${YELLOW}Do you want to configure SSL with Let's Encrypt? (y/n):${NC}"
    read -p "> " USE_SSL
    USE_SSL=${USE_SSL:-"y"}

    # Timezone
    echo ""
    echo -e "${YELLOW}Enter your timezone (e.g., Europe/London, America/New_York):${NC}"
    read -p "> " TIMEZONE
    TIMEZONE=${TIMEZONE:-"UTC"}

    # Confirm
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                    CONFIRM SETTINGS                           ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Domain:         ${GREEN}$FQDN${NC}"
    echo -e "  Panel Name:     ${GREEN}$PANEL_NAME${NC}"
    echo -e "  Admin Email:    ${GREEN}$ADMIN_EMAIL${NC}"
    echo -e "  Admin Username: ${GREEN}$ADMIN_USER${NC}"
    echo -e "  SSL:            ${GREEN}$USE_SSL${NC}"
    echo -e "  Timezone:       ${GREEN}$TIMEZONE${NC}"
    echo ""
    echo -e "${YELLOW}Is this correct? (y/n):${NC}"
    read -p "> " CONFIRM

    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo -e "${YELLOW}Restarting configuration...${NC}"
        get_user_input
    fi
}

# Install dependencies
install_dependencies() {
    echo ""
    echo -e "${CYAN}[1/8] Installing dependencies...${NC}"

    apt update -y
    apt upgrade -y

    # Add PHP repository
    apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg

    if [[ "$OS" == "ubuntu" ]]; then
        add-apt-repository -y ppa:ondrej/php
    elif [[ "$OS" == "debian" ]]; then
        curl -sSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
        echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/sury-php.list
    fi

    # Add MariaDB repository
    curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash

    # Add Node.js repository
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -

    apt update -y

    # Install packages
    apt install -y \
        php8.2 php8.2-fpm php8.2-cli php8.2-common php8.2-gd php8.2-mysql php8.2-mbstring \
        php8.2-bcmath php8.2-xml php8.2-curl php8.2-zip php8.2-intl php8.2-redis \
        mariadb-server nginx redis-server nodejs tar unzip git

    # Fix mariadb installation issues on Ubuntu 22.04
    # Some versions need explicit initialization
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        echo -e "${BLUE}Initializing MariaDB...${NC}"
        mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql 2>/dev/null || true
    fi

    # Ensure MariaDB can be started
    chown -R mysql:mysql /var/lib/mysql
    chmod 755 /var/lib/mysql

    # Install Composer
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

    # Install Yarn
    npm install -g yarn

    echo -e "${GREEN}✓ Dependencies installed${NC}"
}

# Configure MariaDB
configure_database() {
    echo ""
    echo -e "${CYAN}[2/8] Configuring database...${NC}"

    systemctl start mariadb
    systemctl enable mariadb

    # Wait for MariaDB to be ready
    sleep 5
    
    # Check if MariaDB is running
    if ! systemctl is-active --quiet mariadb; then
        echo -e "${RED}Error: MariaDB failed to start!${NC}"
        systemctl status mariadb
        exit 1
    fi

    # Secure MariaDB - handle socket authentication on Ubuntu 22.04
    mysql -u root <<'EOF'
ALTER USER 'root'@'localhost' IDENTIFIED BY 'TEMP_ROOT_PASS';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
FLUSH PRIVILEGES;
EOF

    # Update root password with actual password
    mysql -u root -pTEMP_ROOT_PASS <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
FLUSH PRIVILEGES;
EOF

    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to set root password. MariaDB may not be properly initialized.${NC}"
        exit 1
    fi

    # Create panel database and user
    mysql -u root -p"${DB_ROOT_PASS}" <<EOF
CREATE DATABASE IF NOT EXISTS panel;
CREATE USER IF NOT EXISTS 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to create panel database and user.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Database configured${NC}"
}

# Download and install panel
install_panel() {
    echo ""
    echo -e "${CYAN}[3/8] Downloading and installing panel...${NC}"

    # Create directory
    mkdir -p "$INSTALL_DIR" || { echo -e "${RED}Error: Failed to create installation directory${NC}"; exit 1; }
    cd "$INSTALL_DIR" || { echo -e "${RED}Error: Failed to change to installation directory${NC}"; exit 1; }

    # Download panel
    echo -e "${BLUE}Downloading panel package...${NC}"
    curl -Lo panel.tar.gz "${GITHUB_URL}/releases/latest/download/pterodactyl-addons-panel.tar.gz"

    # Extract
    echo -e "${BLUE}Extracting panel...${NC}"
    tar -xzf panel.tar.gz
    rm panel.tar.gz

    # Set permissions if directories exist
    if [ -d "storage" ]; then
        chmod -R 755 storage/
    fi
    if [ -d "bootstrap/cache" ]; then
        chmod -R 755 bootstrap/cache/
    fi

    echo -e "${GREEN}✓ Panel downloaded and extracted${NC}"
}

# Configure panel
configure_panel() {
    echo ""
    echo -e "${CYAN}[4/8] Configuring panel...${NC}"

    cd "$INSTALL_DIR" || { echo -e "${RED}Error: Failed to change to installation directory${NC}"; exit 1; }

    # Copy environment file
    if [ ! -f ".env.example" ]; then
        echo -e "${RED}Error: .env.example file not found${NC}"
        exit 1
    fi
    cp .env.example .env || { echo -e "${RED}Error: Failed to copy environment file${NC}"; exit 1; }

    # Install Composer dependencies
    echo -e "${BLUE}Installing PHP dependencies...${NC}"
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --no-interaction || { echo -e "${RED}Error: Composer install failed${NC}"; exit 1; }

    # Generate app key
    php artisan key:generate --force || { echo -e "${RED}Error: Failed to generate app key${NC}"; exit 1; }

    # Configure environment
    if ! php artisan p:environment:setup \
        --author="$ADMIN_EMAIL" \
        --url="https://$FQDN" \
        --timezone="$TIMEZONE" \
        --cache=redis \
        --session=redis \
        --queue=redis \
        --redis-host=127.0.0.1 \
        --redis-pass= \
        --redis-port=6379 \
        --settings-ui=true; then
        echo -e "${RED}Error: Environment setup failed${NC}"
        exit 1
    fi

    if ! php artisan p:environment:database \
        --host=127.0.0.1 \
        --port=3306 \
        --database=panel \
        --username=pterodactyl \
        --password="$DB_PASS"; then
        echo -e "${RED}Error: Database configuration failed${NC}"
        exit 1
    fi

    # Update panel name in .env
    sed -i "s/APP_NAME=.*/APP_NAME=\"$PANEL_NAME\"/" .env

    echo -e "${GREEN}✓ Panel configured${NC}"
}

# Run migrations and seed
setup_database_tables() {
    echo ""
    echo -e "${CYAN}[5/8] Setting up database tables...${NC}"

    cd "$INSTALL_DIR" || { echo -e "${RED}Error: Failed to change to installation directory${NC}"; exit 1; }

    # Run migrations
    php artisan migrate --seed --force || { echo -e "${RED}Error: Database migrations failed${NC}"; exit 1; }

    # Create admin user
    php artisan p:user:make \
        --email="$ADMIN_EMAIL" \
        --username="$ADMIN_USER" \
        --name-first="Admin" \
        --name-last="User" \
        --password="$ADMIN_PASS" \
        --admin=1 || { echo -e "${RED}Error: Failed to create admin user${NC}"; exit 1; }

    echo -e "${GREEN}✓ Database tables created${NC}"
}

# Build frontend
build_frontend() {
    echo ""
    echo -e "${CYAN}[6/8] Building frontend assets...${NC}"

    cd "$INSTALL_DIR" || { echo -e "${RED}Error: Failed to change to installation directory${NC}"; exit 1; }

    # Install Node dependencies
    echo -e "${BLUE}Installing Node.js dependencies...${NC}"
    yarn install --frozen-lockfile || { echo -e "${RED}Error: Yarn install failed${NC}"; exit 1; }

    # Build
    echo -e "${BLUE}Building frontend (this may take a few minutes)...${NC}"
    yarn build:production || { echo -e "${RED}Error: Frontend build failed${NC}"; exit 1; }

    echo -e "${GREEN}✓ Frontend built${NC}"
}

# Configure webserver
configure_webserver() {
    echo ""
    echo -e "${CYAN}[7/8] Configuring webserver...${NC}"

    # Create Nginx config
    cat > /etc/nginx/sites-available/pterodactyl.conf <<EOF
server {
    listen 80;
    server_name $FQDN;

    root $INSTALL_DIR/public;
    index index.html index.htm index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

    # Enable site
    ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default

    # Test and reload
    if ! nginx -t; then
        echo -e "${RED}Error: Nginx configuration test failed${NC}"
        exit 1
    fi
    systemctl reload nginx || { echo -e "${RED}Error: Failed to reload nginx${NC}"; exit 1; }

    # Configure SSL if requested
    if [[ "$USE_SSL" == "y" || "$USE_SSL" == "Y" ]]; then
        echo -e "${BLUE}Setting up SSL with Let's Encrypt...${NC}"
        apt install -y certbot python3-certbot-nginx
        certbot --nginx -d "$FQDN" --non-interactive --agree-tos --email "$ADMIN_EMAIL" --redirect
    fi

    echo -e "${GREEN}✓ Webserver configured${NC}"
}

# Set permissions and create services
finalize_installation() {
    echo ""
    echo -e "${CYAN}[8/8] Finalizing installation...${NC}"

    cd "$INSTALL_DIR" || { echo -e "${RED}Error: Failed to change to installation directory${NC}"; exit 1; }

    # Set permissions
    chown -R www-data:www-data "$INSTALL_DIR"/* || { echo -e "${RED}Error: Failed to set file permissions${NC}"; exit 1; }

    # Create queue worker service
    cat > /etc/systemd/system/pteroq.service <<EOF
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php $INSTALL_DIR/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    # Create cron job (avoid duplicates)
    if ! crontab -l 2>/dev/null | grep -q "$INSTALL_DIR/artisan schedule:run"; then
        (crontab -l 2>/dev/null; echo "* * * * * php $INSTALL_DIR/artisan schedule:run >> /dev/null 2>&1") | crontab -
    fi

    # Enable and start services
    systemctl daemon-reload
    systemctl enable --now redis-server || { echo -e "${RED}Error: Failed to start redis-server${NC}"; exit 1; }
    systemctl enable --now php8.2-fpm || { echo -e "${RED}Error: Failed to start php8.2-fpm${NC}"; exit 1; }
    systemctl enable --now mariadb || { echo -e "${RED}Error: Failed to start mariadb${NC}"; exit 1; }
    sleep 2
    systemctl enable --now nginx || { echo -e "${RED}Error: Failed to start nginx${NC}"; exit 1; }
    systemctl enable --now pteroq || { echo -e "${RED}Error: Failed to start pteroq${NC}"; exit 1; }

    # Clear caches
    php artisan config:cache || { echo -e "${YELLOW}Warning: Failed to cache config${NC}"; }
    php artisan view:cache || { echo -e "${YELLOW}Warning: Failed to cache views${NC}"; }
    php artisan route:cache || { echo -e "${YELLOW}Warning: Failed to cache routes${NC}"; }

    echo -e "${GREEN}✓ Installation finalized${NC}"
}

# Print completion message
print_complete() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}           INSTALLATION COMPLETE! 🎉                           ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${WHITE}Panel URL:${NC}        ${CYAN}https://$FQDN${NC}"
    echo -e "  ${WHITE}Admin Email:${NC}      ${CYAN}$ADMIN_EMAIL${NC}"
    echo -e "  ${WHITE}Admin Username:${NC}   ${CYAN}$ADMIN_USER${NC}"
    echo ""
    echo -e "${YELLOW}Database Credentials (save these!):${NC}"
    echo -e "  ${WHITE}Database:${NC}         ${CYAN}panel${NC}"
    echo -e "  ${WHITE}Username:${NC}         ${CYAN}pterodactyl${NC}"
    echo -e "  ${WHITE}Password:${NC}         ${CYAN}$DB_PASS${NC}"
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${WHITE}Included Features:${NC}"
    echo -e "  ${GREEN}✓${NC} Minecraft Addons (Mods, Plugins, Versions, Modpacks)"
    echo -e "  ${GREEN}✓${NC} Rust Addons (uMod Plugins, RCON, Maps, Wipe Manager)"
    echo -e "  ${GREEN}✓${NC} CS2 Addons (Plugins, RCON, Maps, Workshop)"
    echo -e "  ${GREEN}✓${NC} FiveM Addons (Resources, Config, Players)"
    echo -e "  ${GREEN}✓${NC} ARK Addons (Mods, Config, Cluster Manager)"
    echo -e "  ${GREEN}✓${NC} GMod Addons (Addons, RCON, Players)"
    echo -e "  ${GREEN}✓${NC} Valheim Addons (Mods, Worlds, Config)"
    echo -e "  ${GREEN}✓${NC} 7 Days to Die Addons (Mods, Config)"
    echo -e "  ${GREEN}✓${NC} Admin: Billing, Subdomains, Resource Upgrades"
    echo -e "  ${GREEN}✓${NC} Themes: Neon Gaming, Eltahost Premium"
    echo ""
    echo -e "${PURPLE}Thank you for using Pterodactyl Addons Panel!${NC}"
    echo -e "${PURPLE}Made with ❤️ by elta.one (EltaGamingHost)${NC}"
    echo -e "${PURPLE}Given away for FREE - Enjoy!${NC}"
    echo ""
}

# Main function
main() {
    print_banner
    check_root
    detect_os
    get_user_input
    install_dependencies
    configure_database
    install_panel
    configure_panel
    setup_database_tables
    build_frontend
    configure_webserver
    finalize_installation
    print_complete
}

# Run
main
