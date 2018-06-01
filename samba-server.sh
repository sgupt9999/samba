#!/bin/bash
# Create samba server with user defined configuration options
# Start of User inputs
#################################################
SHAREDDIR1="/srvshare1"
SAMBASHARE1="share1"
SHAREDDIR2="/srvshare2"
SAMBASHARE2="share2"
SHAREDDIR3="/srvshare3"
SAMBASHARE3="share3"
SHAREDDIR4="/srvshare4"
SAMBASHARE4="share4"
SHAREDDIR5="/home/sambauser5"
SAMBASHARE5="share5"
USER1="sambauser1"
UID1="1010"
PASSWORD1="redhat1"
USER2="sambauser2"
UID2="1011"
PASSWORD2="redhat2"
USER3="sambauser3"
UID3="1012"
PASSWORD3="redhat3"
USER4="sambauser4"
UID4="1013"
PASSWORD4="redhat4"
GROUP1="team"
GID1="1020"

# firewalld should be up and running
FIREWALL="yes"
#FIREWALL="no"
#################################################
# End of user inputs

if [[ $EUID != "0" ]]
then
	echo "Error. You need to have root privileges to run this script"
	exit 1
else
	echo "This script will install SAMBA server utilities on this machine"
	echo "The script will also create 4 test users and 1 test group"
        echo "It will also create 4 different shares based on different config specs"
fi

PACKAGES="samba samba-common samba-client cifs-utils"
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
	yum remove -y -q  $PACKAGES > /dev/null 2>&1
fi

echo "Installing packages......."
yum install -y -q $PACKAGES > /dev/null 2>&1
echo "Done"

groupdel $GROUP1 > /dev/null 2>&1
groupadd -g $GID1 $GROUP1
userdel -fr $USER1 > /dev/null 2>&1
useradd -u $UID1 $USER1 -G $GROUP1
smbpasswd -x $USER1 > /dev/null 2>&1
(echo $PASSWORD1; echo $PASSWORD1) | smbpasswd -a -s $USER1 > /dev/null 2>&1
userdel -fr $USER2 > /dev/null 2>&1
useradd -u $UID2 $USER2
smbpasswd -x $USER2 > /dev/null 2>&1
(echo $PASSWORD2; echo $PASSWORD2) | smbpasswd -a -s $USER2 > /dev/null 2>&1
userdel -fr $USER3 > /dev/null 2>&1
useradd -u $UID3 $USER3 -G $GROUP1
smbpasswd -x $USER3 > /dev/null 2>&1
(echo $PASSWORD3; echo $PASSWORD3) | smbpasswd -a -s $USER3 > /dev/null 2>&1
userdel -fr $USER4 > /dev/null 2>&1
useradd -u $UID4 $USER4
smbpasswd -x $USER4 > /dev/null 2>&1
(echo $PASSWORD4; echo $PASSWORD4) | smbpasswd -a -s $USER4 > /dev/null 2>&1

rm -rf $SHAREDDIR1
rm -rf $SHAREDDIR2
rm -rf $SHAREDDIR3
rm -rf $SHAREDDIR4
mkdir $SHAREDDIR1
mkdir $SHAREDDIR2
mkdir $SHAREDDIR3
mkdir $SHAREDDIR4


# The permissions should be controlled from the samba config file
chmod 777 $SHAREDDIR1
chmod 777 $SHAREDDIR2
chmod 2770 $SHAREDDIR3
chgrp $GROUP1 $SHAREDDIR3
chmod 777 $SHAREDDIR4

# First share - Only user1 has login and write permissions
echo >> /etc/samba/smb.conf
echo "[$SAMBASHARE1]" >> /etc/samba/smb.conf
echo "	comment = My first share" >> /etc/samba/smb.conf
echo "	path = $SHAREDDIR1" >> /etc/samba/smb.conf 
echo "	read only = Yes" >> /etc/samba/smb.conf
echo "	browseable = Yes" >> /etc/samba/smb.conf
echo "	write list = $USER1" >> /etc/samba/smb.conf
echo "	valid users = $USER1" >> /etc/samba/smb.conf
echo "First share configured"

# Second share - user2 has login and write permissions, user1 has login and read permissions
echo >> /etc/samba/smb.conf
echo "[$SAMBASHARE2]" >> /etc/samba/smb.conf
echo "	comment = second share" >> /etc/samba/smb.conf
echo "	path = $SHAREDDIR2" >> /etc/samba/smb.conf 
echo "	read only = Yes" >> /etc/samba/smb.conf
echo "	browseable = Yes" >> /etc/samba/smb.conf
echo "	write list = $USER2" >> /etc/samba/smb.conf
echo "	valid users = $USER1,$USER2" >> /etc/samba/smb.conf
echo "Second share configured"

# Third share - group team has login and write permissions with sgid bit set, user2 can only login
echo >> /etc/samba/smb.conf
echo "[$SAMBASHARE3]" >> /etc/samba/smb.conf
echo "	comment = third share" >> /etc/samba/smb.conf
echo "	path = $SHAREDDIR3" >> /etc/samba/smb.conf 
echo "	read only = Yes" >> /etc/samba/smb.conf
echo "	browseable = Yes" >> /etc/samba/smb.conf
echo "	write list = +$GROUP1" >> /etc/samba/smb.conf
echo "	valid users = +$GROUP1,$USER2" >> /etc/samba/smb.conf
echo "	create mask = 0660" >> /etc/samba/smb.conf
echo "	force create mode = 0660" >> /etc/samba/smb.conf
echo "Third share configured"


# Fourth share - user4 has login and write permissions with max file permissions of 0400. Using a credentials file on the client side
echo >> /etc/samba/smb.conf
echo "[$SAMBASHARE4]" >> /etc/samba/smb.conf
echo "	comment = fourth share" >> /etc/samba/smb.conf
echo "	path = $SHAREDDIR4" >> /etc/samba/smb.conf 
echo "	read only = Yes" >> /etc/samba/smb.conf
echo "	browseable = Yes" >> /etc/samba/smb.conf
echo "	write list = $USER4" >> /etc/samba/smb.conf
echo "	valid users = $USER4" >> /etc/samba/smb.conf
echo "	create mask = 0400" >> /etc/samba/smb.conf
echo "Fourth share configured"

setsebool -P samba_export_all_rw=on
setsebool -P samba_export_all_ro=on

# Activating firewall
if [ $FIREWALL == "yes" ]
then
	firewall-cmd --permanent --add-service samba > /dev/null 2>&1
	firewall-cmd --reload > /dev/null 2>&1
	echo "Firewall activated"
fi


systemctl start smb
systemctl start nmb
systemctl -q enable smb
systemctl -q enable nmb

echo
echo
echo "###########################################"
echo "All shares setup correctly"
echo "###########################################"
smbclient -L localhost -U ${USER1}%${PASSWORD1}
echo "###########################################"
