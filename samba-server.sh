#!/bin/bash
# Create samba server with user defined configuration options
# User inputs
SHAREDDIR1="/srvshare1"
SAMBASHARE1="share1"
SHAREDDIR2="/srvshare2"
SAMBASHARE2="share2"
USER1="sambauser1"
UID1="1010"
PASSWORD1="redhat1"
USER2="sambauser2"
UID2="1011"
PASSWORD2="redhat2"

# End of user inputs

if [[ $EUID != "0" ]]
then
	echo "Error. You need to have root privileges to run this script"
	exit 1
fi

PACKAGES="samba samba-common samba-client"
# samba-client installs smbclient and nmblookup
# samba-common install the configuration files and smbpasswd
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

if ! [ -d $SHAREDDIR1 ]
then
	mkdir $SHAREDDIR1
fi

# The permissions should be controlled from the samba config file
chmod 777 $SHAREDDIR1

# First share - Only user1 has use and write permissions
echo >> /etc/samba/smb.conf
echo "[$SAMBASHARE1]" >> /etc/samba/smb.conf
echo "	comment = My first share" >> /etc/samba/smb.conf
echo "	path = $SHAREDDIR1" >> /etc/samba/smb.conf 
echo "	read only = Yes" >> /etc/samba/smb.conf
echo "	browseable = Yes" >> /etc/samba/smb.conf
echo "	write list = $USER1" >> /etc/samba/smb.conf
echo "	valid users = $USER1" >> /etc/samba/smb.conf

setsebool -P samba_export_all_rw=on
setsebool -P samba_export_all_ro=on

userdel -fr $USER1
useradd -u $UID1 $USER1
smbpasswd -x $USER1
(echo $PASSWORD1; echo $PASSWORD1) | smbpasswd -a -s $USER1
userdel -fr $USER2
useradd -u $UID2 $USER2
smbpasswd -x $USER2
(echo $PASSWORD2; echo $PASSWORD2) | smbpasswd -a -s $USER2

systemctl start smb
systemctl start nmb
systemctl enable smb > /dev/null 2>&1
systemctl enable nmb > /dev/null 2>&1
