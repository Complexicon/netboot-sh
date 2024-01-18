```sh
apk add nano git
apk add alpine-sdk alpine-conf syslinux xorriso squashfs-tools grub grub-efi doas
addgroup root abuild
abuild-keygen -i -a -n
git clone --depth=1 git://git.alpinelinux.org/aports

mkdir ~/iso
aports/scripts/mkimage.sh --outdir ~/iso --arch x86_64 --profile installeriso --repository https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/

```
