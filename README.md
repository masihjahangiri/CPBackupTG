# CyberPanel Backup to Telegram

This script automates sending daily CyberPanel backups to a Telegram group.

## Features
- Uses CyberPanel's built-in backup system.
- Automatically finds and sends the latest backup file to Telegram.
- Can be scheduled with a cron job for daily automation.
- Deletes old backups after a specified time.

## Prerequisites
- A CyberPanel server with WordPress installed.
- A Telegram bot (created via @BotFather).
- Your Telegram group chat ID.

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/cyberpanel-backup-telegram.git
cd cyberpanel-backup-telegram
```

### 2. Configure the Script
Edit the script with your details:
```bash
nano cyberpanel_backup_telegram.sh
```
Update the following:
- `TELEGRAM_BOT_TOKEN` → Your bot's API token.
- `TELEGRAM_CHAT_ID` → Your Telegram group ID (with `-100` prefix).
- `BACKUP_DIR` → The CyberPanel backup directory (default: `/home/backup/`).

### 3. Make the Script Executable
```bash
chmod +x cyberpanel_backup_telegram.sh
```

### 4. Schedule the Script with Cron Job
```bash
crontab -e
```
Add the following line to run the script daily at 12:30 AM:
```bash
30 0 * * * /path/to/cyberpanel_backup_telegram.sh >/dev/null 2>&1
```

### 5. Get Your Telegram Group ID
1. Add your bot to the group.
2. Use this command to get the group ID:
```bash
curl https://api.telegram.org/bot<your_bot_token>/getUpdates
```
3. Look for `chat.id` in the response and use it in the script.

## License
This project is licensed under the MIT License.

