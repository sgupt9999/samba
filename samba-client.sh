#!/bin/bash
# Create samba client as per user defined config options
# User inputs
LOCALDIR1="/myshare1"
SERVERIP="172.31.16.125"
SAMBASHARE1="share1"
SAMBASHARE2="share2"
USER1="sambauser1"
UID1="1010"
PASSWORD1="redhat1"
USER2="sambauser2"
UID2="1011"
PASSWORD2="redhat2"

# End of user inputs



if [[ $EUID != 0 ]] 
then
	echo "Error. you need to have root privileges to run this script"
	exit 1
fi

PACKAGES="samba-client cifs-utils nfs-utils"

umount $LOCALDIR1 > /dev/null 2>&1
rm -rf $LOCALDIR1
mkdir $LOCALDIR1

if yum list installed samba-client > /dev/null 2>&1
then
	yum -y -q remove $PACKAGES > /dev/null 2>&1
fi

echo "Installing packages ..........."
yum install -y -q -e0 $PACKAGES
echo "Done"

userdel -fr $USER1
useradd -u $UID1 $USER1
echo $PASSWORD1 | passwd --stdin $USER1
userdel -fr $USER2
useradd -u $UID2 $USER2
echo $PASSWORD2 | passwd --stdin $USER2


mount -t cifs -o username=$USER1,password=$PASSWORD1 //$SERVERIP/$SAMBASHARE1 $LOCALDIR1
