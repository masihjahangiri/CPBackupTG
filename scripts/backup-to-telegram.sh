#!/bin/bash

# Load environment variables
export $(grep -v '^#' $(dirname "$0")/../.env | xargs)

# Set backup directory (modify if needed)
BACKUP_DIR="/home/backup/"
LATEST_BACKUP=$(ls -t $BACKUP_DIR | head -n1)  # Get the latest backup file
BACKUP_PATH="$BACKUP_DIR$LATEST_BACKUP"

# Check if backup exists
if [ -f "$BACKUP_PATH" ]; then
    echo "Sending backup to Telegram..."
    curl -F "chat_id=$TELEGRAM_CHAT_ID" -F "document=@$BACKUP_PATH" "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendDocument"
    echo "Backup sent successfully! ✅"
else
    echo "No backup file found! ❌"
fi
