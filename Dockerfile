FROM alpine:latest

RUN apk add --no-cache alpine-sdk alpine-conf syslinux xorriso squashfs-tools grub grub-efi doas nano git
WORKDIR /src
RUN git clone --depth=1 git://git.alpinelinux.org/aports
COPY aports/imgoverlay.sh /src/aports/scripts/genapkovl-mkimgoverlay.sh
COPY aports/mkimg.installeriso.sh /src/aports/scripts/mkimg.installeriso.sh
RUN chmod +x aports/scripts/*.sh
RUN addgroup root abuild
RUN SUDO="" abuild-keygen -i -a -n
ENTRYPOINT ["/src/aports/scripts/mkimage.sh", "--outdir", "/github/workspace", "--arch", "x86_64", "--profile", "installeriso", "--repository", "https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/"]
