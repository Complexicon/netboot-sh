profile_installeriso() {
	title="Installer ISO"
	desc="Network connection is required."
	profile_base
	profile_abbrev="install"
	apkovl="overlay.sh"
	image_ext="iso"
	arch="x86_64"
	output_format="iso"
	modloop_sign=no
	apks="$apks agetty gum curl"
}
