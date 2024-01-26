#!/bin/sh
echo "fetching dependencies"
cat > /etc/apk/repositories << EOF; $(echo)

https://dl-cdn.alpinelinux.org/alpine/v$(cut -d'.' -f1,2 /etc/alpine-release)/main/
https://dl-cdn.alpinelinux.org/alpine/v$(cut -d'.' -f1,2 /etc/alpine-release)/community/

EOF
apk update
apk add syslinux ntfs-3g ntfs-3g-progs xxd libc6-compat util-linux fuse coreutils grep wimlib git
modprobe fuse
git clone --depth=1 https://git.cmplx.dev/netboot-sh
cd netboot-sh/cloud-windows
chmod +x *

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

DISKS=$(find_disks)
TARGET_DISK=$(echo "$DISKS" | gum choose | cut -d ' ' -f 1)
echo "Installing Windows to /dev/$TARGET_DISK"

# TODO make iso selection dynamic. see https://github.com/massgravel/msdl

if [ -d /sys/firmware/efi ]
then
  ./do-windows-cloud-install-efi.sh /dev/$TARGET_DISK
else
  ./do-windows-cloud-install-bios.sh /dev/$TARGET_DISK
fi
