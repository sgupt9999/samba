#!/bin/bash
# Create samba server and different configuration options
# User inputs
SHAREDDIR="/myshare1"


# End of user inputs

if [[ $EUID != "0" ]]
then
	echo "Error. You need to have root privileges to run this script"
	exit 1
fi

PACKAGES="samba samba-common samba-client cifs-utils"
# samba-client installs sambaclient and nmblookup
# samba-common install the configuration file
# samba installs server and client software
# cifs utils installs utilities for mounting and managing CIFS mounts

if yum list installed samba > /dev/null 2>&1
then
	echo "Removing pre-installed packages......."
	systemctl -q is-active smb && {
	systemctl -q stop smb
	systemctl -q stop nmb
	systemctl -q disable smb
	systemctl -q disable nmb
	}
	yum remove -y -q -e0 $PACKAGES > /dev/null 2>&1
fi

echo "Installing packages......."
yum install -y -q -e0 $PACKAGES
echo "Done"

systemctl start smb
systemctl start nmb
systemctl enable smb
systemctl enable nmb

if [ -f $SHAREDDIR ]
then
	echo "Directory already there"
else
	mkdir $SHAREDDIR
fi
