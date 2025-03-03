Below is an example of a professional, well-structured bash script that manages CyberPanel backups and sends them to Telegram. It includes:

- A menu-driven interface (installation, configuration, sending backups, status, uninstallation)  
- Customizable scheduling intervals (1h, 6h, 1d, 3d, 7d)  
- Robust error handling and colorized output for better UX  
- Support for credentials via direct input or environment file  
- Single-command GitHub-based installation workflow (example shown)  
- A descriptive and memorable command name (e.g., `cyberTGBackup`)  
- Follows bash best practices for storing secrets and logging  

Feel free to adjust and expand this template to suit your exact environment and use case.

---

## Example `cyberTGBackup` Script

```bash
#!/usr/bin/env bash
#
# cyberTGBackup - Manage CyberPanel backups and send them to Telegram.
#
# This script provides a menu-driven interface to install, configure, send backups,
# check status, and uninstall the service. It supports storing your Telegram API
# credentials either directly or in an .env file, and it can set up cron jobs for
# automated backup sending.

########################
#     CONFIGURATION    #
########################

# Default installation paths (customize as needed)
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/cyberTGBackup"
ENV_FILE="$CONFIG_DIR/.env"
LOG_FILE="/var/log/cyberTGBackup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
RESET='\033[0m'

########################
#   HELPER FUNCTIONS   #
########################

print_header() {
  echo -e "${CYAN}====================================================${RESET}"
  echo -e "${CYAN}  CyberPanel to Telegram Backup Manager (cyberTGBackup)${RESET}"
  echo -e "${CYAN}====================================================${RESET}"
}

log_info() {
  echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] INFO  => $*" | tee -a "$LOG_FILE"
}

log_error() {
  echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR => $*" | tee -a "$LOG_FILE" >&2
}

# Safely load environment variables if file exists
load_env() {
  if [ -f "$ENV_FILE" ]; then
    # shellcheck disable=SC2046
    export $(grep -v '^#' "$ENV_FILE" | xargs -d '\n')
  fi
}

error_exit() {
  log_error "$1"
  echo -e "${RED}Error: $1${RESET}"
  exit 1
}

########################
#   CORE  FUNCTIONS    #
########################

install_script() {
  print_header
  echo -e "Installing cyberTGBackup..."

  # Create necessary directories
  mkdir -p "$CONFIG_DIR" || error_exit "Failed to create $CONFIG_DIR"

  # If called from remote or local, ensure script ends up in INSTALL_DIR
  cp "$0" "$INSTALL_DIR/cyberTGBackup" || error_exit "Failed to copy script to $INSTALL_DIR"
  chmod +x "$INSTALL_DIR/cyberTGBackup"

  # Create a blank .env if it doesn't exist
  if [ ! -f "$ENV_FILE" ]; then
    touch "$ENV_FILE" || error_exit "Failed to create $ENV_FILE"
    chmod 600 "$ENV_FILE"
  fi

  echo -e "${GREEN}Installation complete.${RESET}"
  log_info "Installed cyberTGBackup successfully."
}

configure_script() {
  print_header
  echo -e "Configure Telegram Bot credentials and other settings."

  # Prompt user for input
  read -rp "Enter Telegram Bot Token (or leave blank to keep current): " BOT_TOKEN
  read -rp "Enter Telegram Chat ID (or leave blank to keep current): " CHAT_ID

  # Load existing env first to preserve unchanged vars
  load_env

  # Write or update .env file
  if [ -n "$BOT_TOKEN" ]; then
    sed -i "/^TELEGRAM_BOT_TOKEN=/d" "$ENV_FILE"
    echo "TELEGRAM_BOT_TOKEN=\"$BOT_TOKEN\"" >> "$ENV_FILE"
  fi

  if [ -n "$CHAT_ID" ]; then
    sed -i "/^TELEGRAM_CHAT_ID=/d" "$ENV_FILE"
    echo "TELEGRAM_CHAT_ID=\"$CHAT_ID\"" >> "$ENV_FILE"
  fi

  echo -e "${GREEN}Configuration updated.${RESET}"
  log_info "Configuration updated."
}

send_backup() {
  # Load environment
  load_env

  # Check for required env vars
  if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
    error_exit "Telegram bot token or chat ID not set. Run 'configure' first."
  fi

  print_header
  echo "Sending backup to Telegram..."

  # -----------------------------
  # Example backup steps (adjust for your environment)
  # 1. Generate or find the backup file from CyberPanel
  # 2. Use cURL to send the backup to Telegram
  # -----------------------------
  BACKUP_FILE="/path/to/cyberpanel/backup-$(date +%F_%H%M%S).tar.gz"
  # Example placeholder for backup creation:
  # /usr/local/CyberCP/bin/python /usr/local/CyberCP/plogical/backup.py --path "$BACKUP_FILE"

  # Just a placeholder check to see if a file exists
  if [ ! -f "$BACKUP_FILE" ]; then
    error_exit "Could not find backup file at $BACKUP_FILE"
  fi

  # Send to Telegram
  SEND_RESPONSE=$(curl -sf -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendDocument" \
    -F "chat_id=${TELEGRAM_CHAT_ID}" \
    -F "document=@${BACKUP_FILE}" \
    -F "caption=CyberPanel Backup: $(basename "$BACKUP_FILE")")

  if [ $? -ne 0 ] || [[ $SEND_RESPONSE != *'"ok":true'* ]]; then
    error_exit "Failed to send backup via Telegram."
  fi

  echo -e "${GREEN}Backup sent successfully.${RESET}"
  log_info "Backup $BACKUP_FILE sent successfully."
}

view_status() {
  load_env
  print_header
  echo "=== Script Status ==="
  echo -e "Installed script path: ${YELLOW}$INSTALL_DIR/cyberTGBackup${RESET}"
  echo -e "Config directory: ${YELLOW}$CONFIG_DIR${RESET}"
  echo -e "Environment file: ${YELLOW}$ENV_FILE${RESET}"
  echo -e "Log file: ${YELLOW}$LOG_FILE${RESET}"
  echo

  if [ -f "$ENV_FILE" ]; then
    echo "=== Current Environment Settings ==="
    grep -v '^#' "$ENV_FILE"
  else
    echo -e "${RED}No .env file found at $ENV_FILE.${RESET}"
  fi

  # Check if cron job is set
  echo
  echo "=== Cron Jobs for cyberTGBackup ==="
  crontab -l 2>/dev/null | grep "cyberTGBackup" && true || echo -e "${YELLOW}No cron jobs found for cyberTGBackup.${RESET}"
  echo
}

uninstall_script() {
  print_header
  echo "Uninstalling cyberTGBackup..."

  # Remove script
  if [ -f "$INSTALL_DIR/cyberTGBackup" ]; then
    rm -f "$INSTALL_DIR/cyberTGBackup"
    echo -e "${GREEN}Removed $INSTALL_DIR/cyberTGBackup${RESET}"
    log_info "Removed $INSTALL_DIR/cyberTGBackup"
  else
    echo -e "${YELLOW}$INSTALL_DIR/cyberTGBackup not found, skipping...${RESET}"
  fi

  # Optionally remove config
  read -rp "Remove configuration directory ($CONFIG_DIR)? (y/N): " remove_config
  if [[ "$remove_config" =~ ^[Yy]$ ]]; then
    rm -rf "$CONFIG_DIR"
    echo -e "${GREEN}Removed configuration directory $CONFIG_DIR${RESET}"
    log_info "Removed configuration directory $CONFIG_DIR"
  fi

  # Remove cron entries
  crontab -l 2>/dev/null | grep -v "cyberTGBackup" | crontab - 2>/dev/null || true

  echo -e "${GREEN}Uninstallation complete.${RESET}"
}

set_schedule() {
  # Load environment in case we need it
  load_env
  print_header
  echo -e "Set cron schedule for automated backup sending."

  echo -e "Choose an interval:\n"
  echo "1) Every 1 hour"
  echo "2) Every 6 hours"
  echo "3) Every 1 day"
  echo "4) Every 3 days"
  echo "5) Every 7 days"
  echo "6) Cancel"

  read -rp "Select an option [1-6]: " choice
  local cron_expr

  case "$choice" in
    1) cron_expr="0 * * * *" ;;
    2) cron_expr="0 */6 * * *" ;;
    3) cron_expr="0 0 * * *" ;;
    4) 
       # A typical approach for every 3 days is something like day-of-month intervals.
       # But day-of-month intervals can be tricky with months that have fewer than 30/31 days.
       # For simplicity, run at midnight on day 1, 4, 7, 10, etc. 
       cron_expr="0 0 */3 * *"
       ;;
    5) cron_expr="0 0 */7 * *" ;;
    6) echo "Canceled."; return ;;
    *) echo -e "${RED}Invalid choice, canceling.${RESET}"; return ;;
  esac

  # Remove existing schedule lines
  current_cron=$(crontab -l 2>/dev/null | grep -v "cyberTGBackup" || true)
  {
    echo "$current_cron"
    echo "$cron_expr $INSTALL_DIR/cyberTGBackup send"
  } | crontab -

  echo -e "${GREEN}Cron schedule set to: '$cron_expr'${RESET}"
  log_info "Cron schedule set to: '$cron_expr'"
}

print_menu() {
  print_header
  echo -e "Select an option:"
  echo "1) Install"
  echo "2) Configure"
  echo "3) Send Backup"
  echo "4) View Status"
  echo "5) Set Backup Schedule"
  echo "6) Uninstall"
  echo "7) Exit"
}

########################
#        MAIN          #
########################

main_menu() {
  while true; do
    print_menu
    read -rp "Enter choice [1-7]: " choice
    case "$choice" in
      1) install_script ;;
      2) configure_script ;;
      3) send_backup ;;
      4) view_status ;;
      5) set_schedule ;;
      6) uninstall_script ;;
      7) echo -e "Exiting..."; exit 0 ;;
      *) echo -e "${RED}Invalid choice. Please try again.${RESET}" ;;
    esac
    echo
    read -rp "Press [Enter] to continue..."
  done
}

# If script is called with arguments, we can parse them to allow direct calls
# e.g. "cyberTGBackup send" to skip menu. Adjust as needed.
case "$1" in
  install)       install_script ;;
  configure)     configure_script ;;
  send)          send_backup ;;
  status)        view_status ;;
  schedule)      set_schedule ;;
  uninstall)     uninstall_script ;;
  *)             main_menu ;;
esac
```

### How to Use This Template

1. **Place this script in a GitHub repository**  
   - For example, create a GitHub repo named `cyberTGBackup` and place the script above in a file named `cyberTGBackup`.

2. **Make it installable via a single command**  
   - Create a simple `install.sh` in the same repository that downloads and installs the script.  
   - Example `install.sh`:
     ```bash
     #!/usr/bin/env bash
     set -e

     REPO_URL="https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/cyberTGBackup"

     # Download script to /tmp and run its install function
     curl -s -o /tmp/cyberTGBackup "$REPO_URL"
     chmod +x /tmp/cyberTGBackup
     /tmp/cyberTGBackup install
     ```

   - Then your users can run:  
     ```bash
     curl -s https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install.sh | bash
     ```

3. **Credential Management**  
   - The script stores credentials in `/etc/cyberTGBackup/.env` by default (with `chmod 600` to limit access).  
   - You can also set `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` as environment variables directly if desired.  

4. **Scheduling**  
   - In the menu, choose “Set Backup Schedule” to configure cron intervals.  
   - This inserts a line in your crontab that calls `cyberTGBackup send` at the specified interval.  

5. **Uninstallation**  
   - Use the “Uninstall” option in the menu. It will remove the script, optionally remove the config directory, and clear the cron entries.  

6. **Logging**  
   - Logs are appended to `/var/log/cyberTGBackup.log` by default.

7. **Enhancing for Production**  
   - Replace the placeholder backup generation step with your actual CyberPanel backup command or script.  
   - Improve error handling to match your environment’s needs (e.g., verifying CyberPanel is installed, ensuring `curl` exists).  
   - Validate that your Telegram bot can handle file sizes if backups are large (Telegram has file size limits).  

---

## Key Best Practices Demonstrated

1. **Secure credential storage**:  
   - Credentials go into `CONFIG_DIR/.env` with strict permissions.  

2. **Modular approach**:  
   - Functions handle self-contained tasks (install, configure, send, etc.).  

3. **Colorized outputs and logging**:  
   - Improves user readability and ensures important messages are saved to a log.  

4. **Menu-driven interface**:  
   - Provides a user-friendly experience.  

5. **Single-command installation**:  
   - Streamlines setup for yourself or other users.  

6. **Cron-based scheduling**:  
   - Automated backups at user-defined intervals.  

7. **Documentation and clarity**:  
   - Clear comments, variable names, and straightforward structure.  

---

Use this template as a foundation and tailor it to your specific CyberPanel setup. Once integrated, you’ll have an easy-to-use, robust script to manage backups and send them securely to Telegram.