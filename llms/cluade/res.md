I'll create a comprehensive bash script to manage CyberPanel backups and send them to Telegram based on your requirements.

```bash
#!/bin/bash

# ====================================
# CyberPanel Telegram Backup Manager
# Author: Claude
# Version: 1.0
# Description: Manages CyberPanel backups and sends them to Telegram
# ====================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Config file location
CONFIG_DIR="/etc/cybertel"
CONFIG_FILE="$CONFIG_DIR/config.conf"
LOG_FILE="$CONFIG_DIR/cybertel.log"
SERVICE_FILE="/etc/systemd/system/cybertel.service"
TIMER_FILE="/etc/systemd/system/cybertel.timer"
SCRIPT_PATH="/usr/local/bin/cybertel"

# Function to display header
display_header() {
    clear
    echo -e "${CYAN}============================================${NC}"
    echo -e "${CYAN}     CyberPanel Telegram Backup Manager    ${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo
}

# Function to log messages
log_message() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
    fi
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    if [[ "$level" == "ERROR" ]]; then
        echo -e "${RED}[$level] $message${NC}" >&2
    elif [[ "$level" == "WARNING" ]]; then
        echo -e "${YELLOW}[$level] $message${NC}" >&2
    elif [[ "$level" == "SUCCESS" ]]; then
        echo -e "${GREEN}[$level] $message${NC}"
    else
        echo -e "[$level] $message"
    fi
}

# Function to check if required commands exist
check_requirements() {
    local missing_requirements=0
    
    for cmd in curl jq systemctl find grep; do
        if ! command -v "$cmd" &> /dev/null; then
            log_message "Required command not found: $cmd" "ERROR"
            missing_requirements=1
        fi
    done
    
    # Check for CyberPanel
    if [[ ! -d "/usr/local/CyberCP" ]]; then
        log_message "CyberPanel installation not found" "ERROR"
        missing_requirements=1
    fi
    
    if [[ $missing_requirements -eq 1 ]]; then
        log_message "Please install missing requirements and try again" "ERROR"
        exit 1
    fi
    
    return 0
}

# Function to load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        return 0
    else
        return 1
    fi
}

# Function to save configuration
save_config() {
    mkdir -p "$CONFIG_DIR"
    
    cat > "$CONFIG_FILE" << EOF
# CyberPanel Telegram Backup Manager Configuration
# Generated on $(date)

# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID"

# Backup Configuration
BACKUP_DIR="$BACKUP_DIR"
BACKUP_RETENTION_DAYS="$BACKUP_RETENTION_DAYS"
BACKUP_INTERVAL="$BACKUP_INTERVAL"

# Notification Settings
NOTIFY_ON_SUCCESS="$NOTIFY_ON_SUCCESS"
NOTIFY_ON_FAILURE="$NOTIFY_ON_FAILURE"
EOF
    
    chmod 600 "$CONFIG_FILE"
    log_message "Configuration saved to $CONFIG_FILE" "SUCCESS"
}

# Function to configure the script
configure_script() {
    display_header
    echo -e "${BLUE}Configuration Setup${NC}"
    echo
    
    # Load existing configuration if available
    if load_config; then
        echo -e "Existing configuration found. Update configuration? [y/N]: "
        read -r update_config
        
        if [[ ! "$update_config" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    # Telegram Bot configuration
    echo -e "\n${BLUE}Telegram Bot Configuration${NC}"
    echo -e "Enter your Telegram Bot Token: "
    read -r TELEGRAM_BOT_TOKEN
    
    echo -e "Enter your Telegram Chat ID: "
    read -r TELEGRAM_CHAT_ID
    
    # Test Telegram connection
    echo -e "\nTesting Telegram connection..."
    test_result=$(curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="CyberPanel Telegram Backup Manager: Test message")
    
    if echo "$test_result" | grep -q '"ok":true'; then
        log_message "Telegram connection successful" "SUCCESS"
    else
        log_message "Telegram connection failed. Please check your bot token and chat ID" "ERROR"
        echo -e "Continue anyway? [y/N]: "
        read -r continue_anyway
        
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Backup configuration
    echo -e "\n${BLUE}Backup Configuration${NC}"
    echo -e "Enter the CyberPanel backup directory [/backup]: "
    read -r BACKUP_DIR
    BACKUP_DIR=${BACKUP_DIR:-/backup}
    
    echo -e "Enter the backup retention period in days [7]: "
    read -r BACKUP_RETENTION_DAYS
    BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}
    
    # Backup interval
    echo -e "\n${BLUE}Backup Interval${NC}"
    echo -e "Select backup interval:"
    echo -e "1) Every hour"
    echo -e "2) Every 6 hours"
    echo -e "3) Daily"
    echo -e "4) Every 3 days"
    echo -e "5) Weekly"
    echo -e "Select [3]: "
    read -r interval_choice
    
    case "${interval_choice:-3}" in
        1) BACKUP_INTERVAL="1h" ;;
        2) BACKUP_INTERVAL="6h" ;;
        3) BACKUP_INTERVAL="1d" ;;
        4) BACKUP_INTERVAL="3d" ;;
        5) BACKUP_INTERVAL="7d" ;;
        *) BACKUP_INTERVAL="1d" ;;
    esac
    
    # Notification settings
    echo -e "\n${BLUE}Notification Settings${NC}"
    echo -e "Notify on successful backups? [Y/n]: "
    read -r notify_success
    NOTIFY_ON_SUCCESS=${notify_success:-Y}
    NOTIFY_ON_SUCCESS=$(echo "$NOTIFY_ON_SUCCESS" | tr '[:lower:]' '[:upper:]')
    
    echo -e "Notify on failed backups? [Y/n]: "
    read -r notify_failure
    NOTIFY_ON_FAILURE=${notify_failure:-Y}
    NOTIFY_ON_FAILURE=$(echo "$NOTIFY_ON_FAILURE" | tr '[:lower:]' '[:upper:]')
    
    # Save configuration
    save_config
    
    # Create systemd service and timer
    create_systemd_service
    
    return 0
}

# Function to create systemd service and timer
create_systemd_service() {
    # Create service file
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=CyberPanel Telegram Backup Manager
After=network.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH --send-backup
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Create timer file based on selected interval
    local timer_value
    case "$BACKUP_INTERVAL" in
        "1h") timer_value="hourly" ;;
        "6h") timer_value="*:0/6" ;;
        "1d") timer_value="daily" ;;
        "3d") timer_value="*-*-1/3" ;;
        "7d") timer_value="weekly" ;;
        *) timer_value="daily" ;;
    esac
    
    cat > "$TIMER_FILE" << EOF
[Unit]
Description=CyberPanel Telegram Backup Manager Timer
Requires=cybertel.service

[Timer]
Unit=cybertel.service
OnCalendar=$timer_value
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    # Reload systemd and enable timer
    systemctl daemon-reload
    systemctl enable cybertel.timer
    systemctl start cybertel.timer
    
    log_message "Systemd service and timer installed" "SUCCESS"
}

# Function to find and send the latest backup
send_backup() {
    if ! load_config; then
        log_message "Configuration not found. Please run --configure first" "ERROR"
        exit 1
    fi
    
    log_message "Looking for latest backup in $BACKUP_DIR" "INFO"
    
    # Find the latest backup file
    latest_backup=$(find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime -"$BACKUP_RETENTION_DAYS" | sort -r | head -n 1)
    
    if [[ -z "$latest_backup" ]]; then
        log_message "No backup files found in $BACKUP_DIR" "ERROR"
        
        if [[ "$NOTIFY_ON_FAILURE" == "Y" ]]; then
            curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
                -d chat_id="$TELEGRAM_CHAT_ID" \
                -d text="CyberPanel Backup Error: No backup files found in $BACKUP_DIR"
        fi
        
        exit 1
    fi
    
    backup_file=$(basename "$latest_backup")
    backup_size=$(du -h "$latest_backup" | cut -f1)
    backup_date=$(date -r "$latest_backup" "+%Y-%m-%d %H:%M:%S")
    
    log_message "Found backup: $backup_file (Size: $backup_size, Date: $backup_date)" "INFO"
    
    # Send the backup file to Telegram
    log_message "Sending backup to Telegram..." "INFO"
    
    send_result=$(curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendDocument" \
        -F chat_id="$TELEGRAM_CHAT_ID" \
        -F document=@"$latest_backup" \
        -F caption="CyberPanel Backup: $backup_file
Size: $backup_size
Date: $backup_date")
    
    if echo "$send_result" | grep -q '"ok":true'; then
        log_message "Backup sent successfully" "SUCCESS"
        
        if [[ "$NOTIFY_ON_SUCCESS" == "Y" ]]; then
            curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
                -d chat_id="$TELEGRAM_CHAT_ID" \
                -d text="CyberPanel Backup Success: $backup_file sent successfully"
        fi
        
        return 0
    else
        error_message=$(echo "$send_result" | jq -r '.description // "Unknown error"')
        log_message "Failed to send backup: $error_message" "ERROR"
        
        if [[ "$NOTIFY_ON_FAILURE" == "Y" ]]; then
            curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
                -d chat_id="$TELEGRAM_CHAT_ID" \
                -d text="CyberPanel Backup Error: Failed to send $backup_file. Error: $error_message"
        fi
        
        return 1
    fi
}

# Function to check and display service status
check_status() {
    display_header
    echo -e "${BLUE}Service Status${NC}\n"
    
    if ! load_config; then
        log_message "Configuration not found. Please run --configure first" "ERROR"
        return 1
    fi
    
    # Check if service is enabled
    if systemctl is-enabled cybertel.timer &> /dev/null; then
        echo -e "Service status: ${GREEN}Enabled${NC}"
    else
        echo -e "Service status: ${RED}Disabled${NC}"
    fi
    
    # Check if service is active
    if systemctl is-active cybertel.timer &> /dev/null; then
        echo -e "Service activity: ${GREEN}Active${NC}"
    else
        echo -e "Service activity: ${RED}Inactive${NC}"
    fi
    
    # Display next scheduled run
    next_run=$(systemctl list-timers cybertel.timer --no-pager | grep cybertel | awk '{print $3, $4, $5}')
    if [[ -n "$next_run" ]]; then
        echo -e "Next scheduled run: ${YELLOW}$next_run${NC}"
    else
        echo -e "Next scheduled run: ${RED}Not scheduled${NC}"
    fi
    
    # Display configuration
    echo -e "\n${BLUE}Configuration${NC}"
    echo -e "Backup directory: ${YELLOW}$BACKUP_DIR${NC}"
    echo -e "Backup retention: ${YELLOW}$BACKUP_RETENTION_DAYS days${NC}"
    echo -e "Backup interval: ${YELLOW}$BACKUP_INTERVAL${NC}"
    echo -e "Notify on success: ${YELLOW}$NOTIFY_ON_SUCCESS${NC}"
    echo -e "Notify on failure: ${YELLOW}$NOTIFY_ON_FAILURE${NC}"
    
    # Check for recent logs
    echo -e "\n${BLUE}Recent Logs${NC}"
    if [[ -f "$LOG_FILE" ]]; then
        tail -n 5 "$LOG_FILE"
    else
        echo -e "${YELLOW}No logs found${NC}"
    fi
    
    echo
    return 0
}

# Function to uninstall the script
uninstall() {
    display_header
    echo -e "${RED}Uninstall CyberPanel Telegram Backup Manager${NC}\n"
    
    echo -e "Are you sure you want to uninstall? This will remove all configuration and scheduled tasks. [y/N]: "
    read -r confirm_uninstall
    
    if [[ ! "$confirm_uninstall" =~ ^[Yy]$ ]]; then
        log_message "Uninstallation cancelled" "INFO"
        return 0
    fi
    
    # Stop and disable services
    systemctl stop cybertel.timer &> /dev/null
    systemctl disable cybertel.timer &> /dev/null
    
    # Remove files
    rm -f "$SERVICE_FILE" "$TIMER_FILE" "$SCRIPT_PATH"
    
    echo -e "Do you want to keep the configuration and logs? [Y/n]: "
    read -r keep_config
    
    if [[ "$keep_config" =~ ^[Nn]$ ]]; then
        rm -rf "$CONFIG_DIR"
    fi
    
    # Reload systemd
    systemctl daemon-reload
    
    log_message "Uninstallation complete" "SUCCESS"
    return 0
}

# Function to install the script
install_script() {
    display_header
    echo -e "${BLUE}Installing CyberPanel Telegram Backup Manager${NC}\n"
    
    # Check requirements
    check_requirements
    
    # Copy script to /usr/local/bin
    cp "$0" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    
    log_message "Script installed to $SCRIPT_PATH" "SUCCESS"
    
    # Configure the script
    configure_script
    
    echo -e "\n${GREEN}Installation complete!${NC}"
    echo -e "You can now use 'cybertel' command to manage your CyberPanel backups."
    echo
    
    return 0
}

# Function to display help
display_help() {
    echo -e "Usage: cybertel [OPTION]"
    echo -e "Manage CyberPanel backups and send them to Telegram.\n"
    echo -e "Options:"
    echo -e "  --install         Install the script"
    echo -e "  --configure       Configure the script"
    echo -e "  --send-backup     Find and send the latest backup to Telegram"
    echo -e "  --status          Check and display service status"
    echo -e "  --uninstall       Uninstall the script"
    echo -e "  --help            Display this help message"
    echo
}

# Main menu function
main_menu() {
    while true; do
        display_header
        echo -e "${BLUE}Main Menu${NC}\n"
        echo -e "1) Configure"
        echo -e "2) Send backup now"
        echo -e "3) Check status"
        echo -e "4) Uninstall"
        echo -e "5) Exit"
        echo
        echo -e "Enter your choice [1-5]: "
        read -r menu_choice
        
        case "$menu_choice" in
            1) configure_script ;;
            2) send_backup ;;
            3) check_status; echo -e "\nPress Enter to continue..."; read ;;
            4) uninstall; break ;;
            5) break ;;
            *) echo -e "${RED}Invalid choice. Please try again.${NC}"; sleep 1 ;;
        esac
    done
}

# Main script execution
if [[ "$#" -eq 0 ]]; then
    # No arguments, show the menu
    main_menu
else
    # Process command line arguments
    case "$1" in
        --install)
            install_script
            ;;
        --configure)
            configure_script
            ;;
        --send-backup)
            send_backup
            ;;
        --status)
            check_status
            ;;
        --uninstall)
            uninstall
            ;;
        --help)
            display_help
            ;;
        *)
            echo -e "${RED}Invalid option: $1${NC}" >&2
            display_help
            exit 1
            ;;
    esac
fi

exit 0

```

## CyberTel: CyberPanel Telegram Backup Manager

I've developed a comprehensive bash script called "CyberTel" that meets all your requirements for managing CyberPanel backups and sending them to Telegram. This solution provides a professional, user-friendly interface with robust functionality.

### Key Features

1. **User-Friendly Interface**: Includes both an interactive menu system and command-line options for flexibility.

2. **Customizable Scheduling**: Supports multiple backup intervals (1h, 6h, 1d, 3d, 7d) through systemd timers.

3. **Robust Error Handling**: Comprehensive error checking and colorized output for improved user experience.

4. **Flexible Configuration**: Supports direct credential input during setup and secure configuration storage.

5. **Easy Installation**: Can be installed via a single command once placed in a GitHub repository.

6. **Descriptive Command Name**: The script uses "cybertel" as its command, clearly indicating its purpose.

### Installation

Once you place this script in a GitHub repository, users can install it with a single command:

```bash
curl -s https://raw.githubusercontent.com/yourusername/repo/main/install.sh | bash
```

### Usage

After installation, users can simply type `cybertel` to access the menu system, or use specific commands:

```bash
cybertel --configure    # Set up Telegram credentials and backup settings
cybertel --send-backup  # Manually send the latest backup to Telegram
cybertel --status       # Check service status and configuration
```

### Implementation Details

The script follows best practices for bash development including:

- Secure storage of credentials (600 permissions on config file)
- Comprehensive logging
- Colorized output for better user experience
- Systemd integration for reliable scheduling
- Proper error handling and reporting

Would you like me to explain any specific part of the implementation in more detail?