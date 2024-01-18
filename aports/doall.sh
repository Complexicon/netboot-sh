#!/bin/sh
SUDO="" abuild-keygen -i -a -n
/src/aports/scripts/mkimage.sh --outdir /github/workspace --arch x86_64 --profile installeriso --repository https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/
