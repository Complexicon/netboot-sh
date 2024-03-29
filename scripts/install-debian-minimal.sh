#!/bin/sh
echo "fetching dependencies"
cat > /etc/apk/repositories << EOF; $(echo)

https://dl-cdn.alpinelinux.org/alpine/v$(cut -d'.' -f1,2 /etc/alpine-release)/main/
https://dl-cdn.alpinelinux.org/alpine/v$(cut -d'.' -f1,2 /etc/alpine-release)/community/

EOF
apk update
apk add util-linux e2fsprogs debootstrap

has_mounted_part() {
	local p
	local sysfsdev="$(echo ${1#/dev/} | sed 's:/:!:g')"
	# parse /proc/mounts for mounted devices
	for p in $(awk '$1 ~ /^\/dev\// {gsub("/dev/", "", $1); gsub("/", "!", $1); print $1}' \
			/proc/mounts 2>/dev/null); do
		[ "$p" = "$sysfsdev" ] && return 0
		[ -e /sys/block/$sysfsdev/$p ] && return 0
	done
	return 1
}

is_available_disk() {
	local dev="$1"

	# check so it does not have mounted partitions
	has_mounted_part $dev && return 1

	return 0
}

find_disks() {
	local p= disk= vendor= model= d= size= busid=
	for p in /sys/block/*/device; do
		local dev="${p%/device}"
		dev=${dev#*/sys/block/}
		if is_available_disk "$dev"; then
  		d=$(echo $dev | sed 's:/:!:g')
  		vendor=$(cat /sys/block/$d/device/vendor 2>/dev/null)
  		model=$(cat /sys/block/$d/device/model 2>/dev/null)
  		busid=$(readlink -f /sys/block/$d/device 2>/dev/null)
  		size=$(awk '{gb = ($1 * 512)/1000000000; printf "%.1f GB\n", gb}' /sys/block/$d/size 2>/dev/null)
			echo "$dev ($size $vendor $model)"
		fi
	done
}

BOOT_PART_SIZE=500M
DISKS=$(find_disks)
TARGET_DISK=$(echo "$DISKS" | gum choose | cut -d ' ' -f 1)
TARGET_DISK=/dev/$TARGET_DISK
echo "Installing Debian to $TARGET_DISK"

prep_disk_bios() {
  echo "creating new mbr partition table for ${TARGET_DISK}"
  echo "label: dos" | sfdisk ${TARGET_DISK} -W always -q # create empty dos partition table
  
  echo "setting up partitions"
  echo ", ${BOOT_PART_SIZE}, c, *" | sfdisk -W always ${TARGET_DISK} -q # create boot partition
  echo ", , 83" | sfdisk -a ${TARGET_DISK} -W always -q # create main partition
  
  echo "final disk geometry"
  sfdisk -l ${TARGET_DISK}
  
  mdev -s
  mdev -s
  
  mkfs.vfat -F 32 ${TARGET_DISK}1
  mkfs.ext4 ${TARGET_DISK}2
}

bootstrap_debian() {
  mount ${TARGET_DISK}2 /mnt
  mkdir /mnt/boot
  mount ${TARGET_DISK}1 /mnt/boot
  debootstrap --arch amd64 --include=systemd-sysv,grub2,iproute2,nano,linux-image-amd64 --variant=minbase bookworm /mnt https://deb.debian.org/debian
  mount --make-rslave --rbind /proc /mnt/proc
  mount --make-rslave --rbind /sys /mnt/sys
  mount --make-rslave --rbind /dev /mnt/dev

  ROOT_UUID=$(blkid ${TARGET_DISK}2 -s UUID -o value)

  echo "UUID=\"${ROOT_UUID}\" / ext4 errors=remount-ro 0 1" >> /mnt/etc/fstab
  
  chroot /mnt env DEBIAN_FRONTEND=noninteractive apt install console-setup ifupdown -y
  echo "set a root password"
  chroot /mnt passwd
  mv /mnt/root/.bashrc /mnt/root/.bashrc.orig
  echo "echo executing first run script..." > /mnt/root/.bashrc
  echo "dpkg-reconfigure keyboard-configuration" >> /mnt/root/.bashrc
  echo "udevadm trigger --subsystem-match=input --action=change" >> /mnt/root/.bashrc

  # todo: setup network config first run

  echo "mv /root/.bashrc.orig /root/.bashrc" >> /mnt/root/.bashrc
}

install_grub_bios() {
  chroot /mnt update-grub
  chroot /mnt grub-install ${TARGET_DISK}
}

if [ -d /sys/firmware/efi ]
then
  echo "UEFI is Work in Progress"
else
  prep_disk_bios
  bootstrap_debian
  install_grub_bios
fi

reboot
