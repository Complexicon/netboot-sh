#!/bin/sh
SUDO="" abuild-keygen -i -a -n
#cp /src/aports/scripts/genapkovl-mkimgoverlay.sh /github/home/.mkimage/overlay.sh
chmod +x /github/home/.mkimage/overlay.sh
/src/aports/scripts/mkimage.sh --outdir /github/workspace --arch x86_64 --profile installeriso --repository https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/ --repository https://dl-cdn.alpinelinux.org/alpine/latest-stable/community/
