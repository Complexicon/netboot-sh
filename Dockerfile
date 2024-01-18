FROM alpine:latest

RUN apk add --no-cache alpine-sdk alpine-conf syslinux xorriso squashfs-tools grub grub-efi doas nano git
WORKDIR /src
RUN git clone --depth=1 git://git.alpinelinux.org/aports
COPY aports/imgoverlay.sh /src/aports/scripts/overlay.sh
COPY aports/mkimg.installeriso.sh /src/aports/scripts/mkimg.installeriso.sh
COPY aports/doall.sh /src/doall.sh
RUN chmod +x aports/scripts/*.sh
RUN chmod +x /src/doall.sh
RUN addgroup root abuild

ENTRYPOINT ["/src/doall.sh"]
