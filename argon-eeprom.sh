#!/bin/bash

echo "*************"
echo " Argon Setup  "
echo "*************"

# Helper variables
ARGONDOWNLOADSERVER=https://download.argon40.com

eepromrpiscript="/usr/bin/rpi-eeprom-config"
eepromconfigscript="/dev/shm/argon-eeprom.py"

# Check if original eeprom script exists before running
if [  -f "$eepromrpiscript" ]
then
    # Update the Raspberry Pi EEPROM
    sudo rpi-eeprom-update
    
    # Perform system update and upgrade
    sudo apt-get update && sudo apt-get upgrade -y

    # Download Argon EEPROM configuration script
    sudo wget $ARGONDOWNLOADSERVER/scripts/argon-rpi-eeprom-config-default.py -O $eepromconfigscript --quiet
    sudo chmod 755 $eepromconfigscript
    sudo $eepromconfigscript
fi
