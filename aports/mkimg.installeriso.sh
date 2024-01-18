profile_installeriso() {
	title="Installer ISO"
	desc="Alpine as it was intended.
		Just enough to get you started.
		Network connection is required."
	profile_base
	profile_abbrev="install"
	apkovl="aports/scripts/genapkovl-mkimgoverlay.sh"
	image_ext="iso"
	arch="aarch64 armv7 x86 x86_64 ppc64le riscv64 s390x"
	output_format="iso"
	#kernel_addons="xtables-addons"
	modloop_sign=no
	apks="$apks agetty debootstrap nano curl wget"
}
