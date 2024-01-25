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
echo "entering debug shell"
