# CyberPanel Telegram Backup Manager

Welcome to the **CyberPanel Telegram Backup Manager** repository. This project provides a robust solution for managing CyberPanel backups and sending them to a specified Telegram chat. The script, named `cybertel`, offers a user-friendly interface and flexible configuration options to ensure seamless backup management.

## Features

- **User-Friendly Interface**: Offers both an interactive menu system and command-line options for ease of use.
- **Customizable Scheduling**: Supports multiple backup intervals (hourly, every 6 hours, daily, every 3 days, weekly) using systemd timers.
- **Robust Error Handling**: Includes comprehensive error checking and colorized output for enhanced user experience.
- **Secure Configuration**: Allows direct credential input during setup with secure storage.
- **Easy Installation**: Installable via a single command from a GitHub repository.
- **Descriptive Command Name**: The script uses "cybertel" as its command, clearly indicating its purpose.

## Installation

To install the CyberPanel Telegram Backup Manager, run the following command:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/masihjahangiri/cyberpanel-backup-telegram/main/install.sh)
```

## Usage

After installation, you can use the `cybertel` command to manage your backups:

- **Configure the Script**: `cybertel --configure`
- **Send Latest Backup**: `cybertel --send-backup`
- **Check Service Status**: `cybertel --status`
- **Uninstall the Script**: `cybertel --uninstall`
- **Help**: `cybertel --help`

## Configuration

During the configuration process, you will be prompted to enter your Telegram Bot Token and Chat ID. The script will test the connection to ensure everything is set up correctly. You can also configure backup settings such as the backup directory, retention period, and notification preferences.

## Systemd Integration

The script integrates with systemd to manage backup schedules. It creates a service and a timer to automate the backup process based on your selected interval.

## Logging

All operations are logged to a file located at `/etc/cybertel/cybertel.log`. This includes information about backup operations, errors, and notifications.

## Uninstallation

To uninstall the script, use the `cybertel --uninstall` command. You will have the option to retain or remove configuration files and logs.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your changes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
