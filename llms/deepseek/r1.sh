#!/usr/bin/env bash
# cyberpanel-tg-backup.sh - CyberPanel Backup Manager with Telegram Integration

# Configuration
CONFIG_DIR="/etc/cyberpanel-tg-backup"
CONFIG_FILE="${CONFIG_DIR}/config.env"
CRON_FILE="${CONFIG_DIR}/cron_job"
SCRIPT_NAME="cyberpanel-tg-backup"
VERSION="1.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize setup
init_config() {
    [ ! -d "$CONFIG_DIR" ] && mkdir -p "$CONFIG_DIR"
    [ ! -f "$CONFIG_FILE" ] && touch "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE" "$CRON_FILE" 2>/dev/null
}

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        echo -e "${RED}Configuration file missing! Run configuration first.${NC}"
        exit 1
    fi
}

# Telegram notification
send_telegram() {
    local message="$1"
    local file="$2"
    
    if [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        echo -e "${RED}Telegram credentials not configured!${NC}"
        return 1
    fi

    if [ -f "$file" ]; then
        response=$(curl -s -F "chat_id=${TELEGRAM_CHAT_ID}" \
            -F "document=@${file}" \
            -F "caption=${message}" \
            "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendDocument")
    else
        response=$(curl -s -X POST \
            -d "chat_id=${TELEGRAM_CHAT_ID}" \
            -d "text=${message}" \
            "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage")
    fi

    if [[ "$response" != *"\"ok\":true"* ]]; then
        echo -e "${RED}Telegram API Error: $response${NC}"
        return 1
    fi
}

# Backup creation and sending
create_backup() {
    echo -e "${BLUE}Creating CyberPanel backup...${NC}"
    backup_output=$(cyberpanel createBackup 2>&1)
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Backup failed: ${backup_output}${NC}"
        send_telegram "❌ Backup Failed: ${backup_output}"
        return 1
    fi
    
    backup_file=$(echo "$backup_output" | grep -oP '/.*\.tar\.gz')
    echo -e "${GREEN}Backup created: ${backup_file}${NC}"
    
    echo -e "${BLUE}Sending to Telegram...${NC}"
    send_telegram "✅ CyberPanel Backup Success\n📅 $(date)\n💾 ${backup_file}" "$backup_file"
}

# Configuration wizard
configure() {
    echo -e "${YELLOW}Telegram Configuration${NC}"
    read -p "Enter Telegram Bot Token: " TELEGRAM_TOKEN
    read -p "Enter Telegram Chat ID: " TELEGRAM_CHAT_ID

    echo -e "${YELLOW}Scheduling Options${NC}"
    PS3="Select backup interval: "
    select interval in "1 Hour" "6 Hours" "1 Day" "3 Days" "7 Days"; do
        case $REPLY in
            1) cron="0 * * * *"; break ;;
            2) cron="0 */6 * * *"; break ;;
            3) cron="0 0 * * *"; break ;;
            4) cron="0 0 */3 * *"; break ;;
            5) cron="0 0 * * 0"; break ;;
            *) echo "Invalid option";;
        esac
    done

    # Save configuration
    echo "TELEGRAM_TOKEN=$TELEGRAM_TOKEN" > "$CONFIG_FILE"
    echo "TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID" >> "$CONFIG_FILE"
    echo "$cron $SCRIPT_NAME --send" > "$CRON_FILE"
    crontab "$CRON_FILE"
    
    echo -e "${GREEN}Configuration saved!${NC}"
}

# Main menu
show_menu() {
    echo -e "${BLUE}
    CyberPanel Backup Manager ${VERSION}
    ##############################
    1) Send Backup Now
    2) Configure Settings
    3) View Status
    4) Uninstall
    5) Exit
    ##############################${NC}"
}

# Installation
install() {
    echo -e "${BLUE}Installing CyberPanel Telegram Backup...${NC}"
    cp "$0" "/usr/local/bin/$SCRIPT_NAME"
    chmod +x "/usr/local/bin/$SCRIPT_NAME"
    init_config
    echo -e "${GREEN}Installation complete! Run '${SCRIPT_NAME} --configure' to setup.${NC}"
}

# Uninstall
uninstall() {
    echo -e "${YELLOW}Removing all components...${NC}"
    rm -f "/usr/local/bin/$SCRIPT_NAME"
    rm -rf "$CONFIG_DIR"
    crontab -l | grep -v "$SCRIPT_NAME" | crontab -
    echo -e "${GREEN}Uninstallation complete!${NC}"
}

# Argument handling
case "$1" in
    "--install")
        install
        ;;
    "--configure")
        configure
        ;;
    "--send")
        load_config
        create_backup
        ;;
    "--uninstall")
        uninstall
        ;;
    *)
        while true; do
            show_menu
            read -p "Select option: " choice
            case $choice in
                1) load_config; create_backup ;;
                2) configure ;;
                3) systemctl status cyberpanel ;;
                4) uninstall; break ;;
                5) exit 0 ;;
                *) echo "Invalid option";;
            esac
        done
        ;;
esac