#!/bin/sh
TARGET_DISK=$1
BOOT_PART_SIZE=200M
WINDOWS_ISO="http://drive.massgrave.dev/de_windows_10_enterprise_ltsc_2019_x64_dvd_34efbe54.iso"
WINBASE="/mnt/win"
BOOTBASE="/mnt/boot"

mkdir -p $BOOTBASE
mkdir -p $WINBASE
mkdir -p /mnt/install

# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "default" will send a empty
# line terminated with a newline to take the fdisk default.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${TARGET_DISK}
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
  +$BOOT_PART_SIZE # 100 MB boot parttion
  t # set type for first partition
  7 # type NTFS
  a # mark bootable
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  t # set type
  2 # second partiton
  7 # NTFS
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

mdev -s
sleep 2
mdev -s

mkfs.ntfs -f ${TARGET_DISK}1
mkfs.ntfs -f ${TARGET_DISK}2

./go-winstall-helper --mount=/mnt/install --url="$WINDOWS_ISO" &
until [ -f /mnt/install/install.wim ]
do
     sleep 1
done
echo "Ready to install. appling image to ${TARGET_DISK}2"
wimapply /mnt/install/install.wim 1 ${TARGET_DISK}2
umount /mnt/install

mount -t ntfs ${TARGET_DISK}1 $BOOTBASE
mount -t ntfs ${TARGET_DISK}2 $WINBASE

./get-ntldr.sh $WINBASE
./transplant-ntldr.sh ${TARGET_DISK}1

cp -R /mnt/win/Windows/Boot/PCAT/ $BOOTBASE/Boot
mv $BOOTBASE/Boot/bootmgr $BOOTBASE
mv $BOOTBASE/Boot/bootnxt $BOOTBASE

./patch-bcd-bios.sh ${TARGET_DISK}2
mv BCD_patched_bios $BOOTBASE/Boot/BCD

dd if=/usr/share/syslinux/mbr.bin of=${TARGET_DISK}

mkdir -p $WINBASE/Windows/Panther
curl -L https://git.cmplx.dev/winsetup/raw/main/unattend.xml > $WINBASE/Windows/Panther/unattend.xml
reboot
