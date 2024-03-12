```yaml
# ARGON HOME ASSISTANT CONFIGURATION
# This configuration script is intended for use with Home Assistant.

echo "*************"
echo " Argon Setup  "
echo "*************"

# Check time if need to 'fix'
NEEDSTIMESYNC=0
LOCALTIME=$(date -u +%s%N | cut -b1-10)
GLOBALTIME=$(curl -s 'http://worldtimeapi.org/api/ip.txt' | grep unixtime | cut -b11-20)
TIMEDIFF=$((GLOBALTIME-LOCALTIME))

# about 26hrs, max timezone difference
if [ $TIMEDIFF -gt 100000 ]
then
	NEEDSTIMESYNC=1
fi

argon_time_error() {
	echo "**********************************************"
	echo "* WARNING: Device time seems to be incorrect *"
	echo "* This may cause problems during setup.      *"
	echo "**********************************************"
	echo "Possible Network Time Protocol Server issue"
	echo "Try running to correct:"
    echo " curl https://download.argon40.com/tools/setntpserver.sh | bash"
}

if [ $NEEDSTIMESYNC -eq 1 ]
then
	argon_time_error
fi

# Helper variables
ARGONDOWNLOADSERVER=https://download.argon40.com
INSTALLATIONFOLDER=/etc/argon
versioninfoscript=$INSTALLATIONFOLDER/argon-versioninfo.sh
uninstallscript=$INSTALLATIONFOLDER/argon-uninstall.sh
shutdownscript=/lib/systemd/system-shutdown/argon-shutdown.sh
configscript=$INSTALLATIONFOLDER/argon-config
unitconfigscript=$INSTALLATIONFOLDER/argon-unitconfig.sh
blstrdacconfigscript=$INSTALLATIONFOLDER/argon-blstrdac.sh

setupmode="Setup"

if [ -f $configscript ]
then
	setupmode="Update"
	echo "Updating files"
else
	sudo mkdir $INSTALLATIONFOLDER
	sudo chmod 755 $INSTALLATIONFOLDER
fi

# Start code lifted from raspi-config
# is_pifive, get_serial_hw and do_serial_hw based on raspi-config

if [ -e /boot/firmware/config.txt ] ; then
  FIRMWARE=/firmware
else
  FIRMWARE=
fi
CONFIG=/boot${FIRMWARE}/config.txt
TMPCONFIG=/dev/shm/argontmp.bak

set_config_var() {
    if ! grep -q -E "$1=$2" $3 ; then
      echo "$1=$2" | sudo tee -a $3 > /dev/null
    fi
}

is_pifive() {
  grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F]4[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$" /proc/cpuinfo
  return $?
}

get_serial_hw() {
  if is_pifive ; then
    if grep -q -E "dtparam=uart0=off" $CONFIG ; then
      echo 1
    elif grep -q -E "dtparam=uart0" $CONFIG ; then
      echo 0
    else
      echo 1
    fi
  else
    if grep -q -E "^enable_uart=1" $CONFIG ; then
      echo 0
    elif grep -q -E "^enable_uart=0" $CONFIG ; then
      echo 1
    elif [ -e /dev/serial0 ] ; then
      echo 0
    else
      echo 1
    fi
  fi
}

do_serial_hw() {
  if [ $1 -eq 0 ] ; then
    if is_pifive ; then
      set_config_var dtparam=uart0 on $CONFIG
    else
      set_config_var enable_uart 1 $CONFIG
    fi
  else
    if is_pifive ; then
      sudo sed $CONFIG -i -e "/dtparam=uart0.*/d"
    else
      set_config_var enable_uart 0 $CONFIG
    fi
  fi
}
# End code lifted from raspi-config

# Reuse is_pifive, set_config_var
set_nvme_default() {
  if is_pifive ; then
    set_config_var dtparam nvme $CONFIG
    set_config_var dtparam=pciex1_gen 3 $CONFIG
  fi
}
set_maxusbcurrent() {
  if is_pifive ; then
    set_config_var max_usb_current 1 $CONFIG
  fi
}

argon_check_pkg() {
    RESULT=$(dpkg-query -W -f='${Status}\n' "$1" 2> /dev/null | grep "installed")

    if [ "" == "$RESULT" ]; then
        echo "NG"
    else
        echo "OK"
    fi
}

CHECKDEVICE="one"	# Hardcoded for argonone
CHECKGPIOMODE="libgpiod" # libgpiod or rpigpio
CHECKPLATFORM="Others"
CHECKPLATFORMVERSION=""
CHECKPLATFORMVERSIONNUM=""

if [ -f "/etc/os-release" ]
then
	source /etc/os-release
	if [ "$ID" = "raspbian" ]
	then
		CHECKPLATFORM="Raspbian"
		CHECKPLATFORMVERSION=$VERSION_ID
	elif [ "$ID" = "debian" ]
	then
		# For backwards compatibility, continue using raspbian
		CHECKPLATFORM="Raspbian"
		CHECKPLATFORMVERSION=$VERSION_ID
	elif [ "$ID" = "ubuntu" ]
	then
		CHECKPLATFORM="Ubuntu"
		CHECKPLATFORMVERSION=$VERSION_ID
	fi
	echo ${CHECKPLATFORMVERSION} | grep -e "\." > /dev/null
	if [ $? -eq 0 ]
	then
		CHECKPLATFORMVERSIONNUM=`cut -d "." -f2 <<< $CHECKPLATFORMVERSION `
		CHECKPLATFORMVERSION=`cut -d "." -f1 <<< $CHECKPLATFORMVERSION `
	fi
fi

gpiopkg="python3-libgpiod"
if [ "$CHECKGPIOMODE" = "rpigpio" ]
then
	if [ "$CHECKPLATFORM" = "Raspbian" ]
	then
		gpiopkg="raspi-gpio python3-r