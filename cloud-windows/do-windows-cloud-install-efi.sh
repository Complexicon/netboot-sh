#!/bin/sh
TARGET_DISK=$1
BOOT_PART_SIZE=200M
WINDOWS_ISO="http://drive.massgrave.dev/de_windows_10_enterprise_ltsc_2019_x64_dvd_34efbe54.iso"
WINBASE="/mnt/win"
BOOTBASE="/mnt/boot"

mkdir -p $BOOTBASE
mkdir -p $WINBASE
mkdir -p /mnt/install

echo "creating new gpt partition table for ${TARGET_DISK}"
echo "label: gpt" | sfdisk ${TARGET_DISK} -q # create empty gpt partition table

echo "setting up partitions"
echo ", ${BOOT_PART_SIZE}, U" | sfdisk ${TARGET_DISK} -q # create efi partition
echo ", ," | sfdisk -a ${TARGET_DISK} -q # create main partition

mkfs.vfat -F 32 -f ${TARGET_DISK}1
mkfs.ntfs -f ${TARGET_DISK}2

./go-winstall-helper --mount=/mnt/install --url="$WINDOWS_ISO" &
until [ -f /mnt/install/install.wim ]
do
     sleep 1
done
echo "Ready to install. appling image to ${TARGET_DISK}2"
wimapply /mnt/install/install.wim 1 ${TARGET_DISK}2
umount /mnt/install

mount -t vfat ${TARGET_DISK}1 $BOOTBASE
mount -t ntfs ${TARGET_DISK}2 $WINBASE
