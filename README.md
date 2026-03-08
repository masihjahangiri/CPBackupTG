# CPBackupTG

Automated backup manager for CyberPanel servers. Finds backup archives and delivers them directly to Telegram via the Bot API. One-liner install, systemd timer scheduling, and configurable retention.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/masihjahangiri/CPBackupTG/main/install.sh | sudo bash
```

The installer walks you through configuration interactively: Telegram bot token, chat ID, backup directory, retention policy, and schedule interval.

## Usage

After installation, use the `cybertel` command:

```bash
cybertel --send-backup     # Send latest backup to Telegram now
cybertel --status          # Show configuration and timer status
cybertel --configure       # Reconfigure settings
cybertel --uninstall       # Remove everything
```

## How It Works

1. CyberPanel creates `.tar.gz` backup archives on its own schedule
2. The systemd timer triggers `cybertel` at your configured interval
3. `cybertel` finds new backup files in the configured directory
4. Each backup is sent to your Telegram chat via the Bot API `sendDocument` endpoint
5. Old backups beyond the retention period are cleaned up

## Scheduling Options

| Interval | Description |
|---|---|
| Hourly | Every hour |
| Every 6 hours | 4 times per day |
| Daily | Once per day |
| Every 3 days | Twice per week |
| Weekly | Once per week |

## Configuration

Configuration is stored at `/etc/cybertel/config.conf`. Logs are written to `/etc/cybertel/cybertel.log`.

| Setting | Description |
|---|---|
| `TELEGRAM_BOT_TOKEN` | Bot token from [@BotFather](https://t.me/BotFather) |
| `TELEGRAM_CHAT_ID` | Target chat or group ID |
| `BACKUP_DIR` | CyberPanel backup directory path |
| `BACKUP_RETENTION` | Number of days to keep backups |
| `BACKUP_INTERVAL` | Systemd timer interval |

## Prerequisites

- CyberPanel server with backup scheduling configured
- Telegram bot token and chat ID
- `curl` installed on the server

## License

MIT
