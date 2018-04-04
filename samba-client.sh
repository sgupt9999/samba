#!/bin/bash
# Create samba client as per user defined config options
# User inputs
LOCALDIR1="/myshare1"
LOCALDIR2="/myshare2"
LOCALDIR3="/myshare3"
LOCALDIR4="/myshare4"
SERVERIP="172.31.16.125"
SAMBASHARE1="share1"
SAMBASHARE2="share2"
SAMBASHARE3="share3"
SAMBASHARE4="share4"
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
CREDENTIALSFILE="/etc/samba/creds.txt"
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
umount $LOCALDIR2 > /dev/null 2>&1
rm -rf $LOCALDIR2
mkdir $LOCALDIR2
umount $LOCALDIR3 > /dev/null 2>&1
rm -rf $LOCALDIR3
mkdir $LOCALDIR3
umount $LOCALDIR4 > /dev/null 2>&1
rm -rf $LOCALDIR4
mkdir $LOCALDIR4

if yum list installed samba-client > /dev/null 2>&1
then
	yum -y -q remove $PACKAGES > /dev/null 2>&1
fi

echo "Installing packages ..........."
yum install -y -q -e0 $PACKAGES
echo "Done"

groupdel $GROUP1
groupadd -g $GID1 $GROUP1
userdel -fr $USER1
useradd -u $UID1 $USER1 -G $GROUP1
echo $PASSWORD1 | passwd --stdin $USER1 > /dev/null 2>&1
userdel -fr $USER2
useradd -u $UID2 $USER2
echo $PASSWORD2 | passwd --stdin $USER2 > /dev/null 2>&1
userdel -fr $USER3
useradd -u $UID3 $USER3 -G $GROUP1
echo $PASSWORD3| passwd --stdin $USER3 > /dev/null 2>&1
userdel -fr $USER4
useradd -u $UID4 $USER4
echo $PASSWORD4 | passwd --stdin $USER4 > /dev/null 2>&1

echo "username=$USER4" > $CREDENTIALSFILE
echo "password=$PASSWORD4" >> $CREDENTIALSFILE

#mount -t cifs -o username=$USER1,password=$PASSWORD1 //$SERVERIP/$SAMBASHARE1 $LOCALDIR1
#mount -t cifs -o username=$USER2,password=$PASSWORD2 //$SERVERIP/$SAMBASHARE2 $LOCALDIR2
#mount -t cifs -o username=$USER3,password=$PASSWORD3 //$SERVERIP/$SAMBASHARE3 $LOCALDIR3
#mount -t cifs -o credentials=$CREDENTIALSFILE //$SERVERIP/$SAMBASHARE4 $LOCALDIR4

if [ -f /etc/fstab_backup ]
then
	cp -f /etc/fstab_backup /etc/fstab
else
	cp -f /etc/fstab /etc/fstab_backup
fi

echo "//$SERVERIP/$SAMBASHARE1 $LOCALDIR1 cifs  _netdev,username=$USER1,password=$PASSWORD1 0 0" >> /etc/fstab
echo "//$SERVERIP/$SAMBASHARE2 $LOCALDIR2 cifs  _netdev,username=$USER2,password=$PASSWORD2 0 0" >> /etc/fstab
echo "//$SERVERIP/$SAMBASHARE3 $LOCALDIR3 cifs  _netdev,username=$USER3,password=$PASSWORD3 0 0" >> /etc/fstab
echo "//$SERVERIP/$SAMBASHARE4 $LOCALDIR4 cifs  _netdev,credentials=$CREDENTIALSFILE 0 0" >> /etc/fstab

echo "All mounts added to /etc/fstab"
