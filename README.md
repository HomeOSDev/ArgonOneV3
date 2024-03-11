# ArgonOneV3
### Argon One V3 Power Button and Fan Control Script Installation Guide

#### Step 1: Configure EEPROM Setting

1. Ensure your Raspberry Pi is connected to the internet and the system time is up-to-date.
2. Execute the following command in the Terminal to optimize power and enable booting from NVMe:

```bash
curl https://download.argon40.com/argon-eeprom.sh | bash
```

3. Reboot your Raspberry Pi.

#### Step 2: Install Argon Control Script and Config.txt Settings

1. Connect your Raspberry Pi to the internet.
2. Run the following command in the Terminal to install the Argon Control Script and configure the `config.txt` settings:

```bash
curl https://download.argon40.com/argon1.sh | bash
```

3. Reboot your Raspberry Pi.

### Uninstallation

To uninstall the Argon ONE V3 script, you have two options:

1. Click the Argon ONE V3 Desktop icon.
2. Alternatively, you can remove the script via Terminal Shell by typing:

```bash
argonone-uninstall
```

Always remember to reboot your Raspberry Pi after changing any configuration or uninstallation for the revised settings to take effect.
