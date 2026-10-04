#!/bin/sh

# Install LED Control packages from the latest GitHub release.  The packages
# are architecture-independent, but are built and published separately for
# each supported OpenWrt release line.

REPOSITORY=NikkyFreaky/OpenWRT
RELEASE_API="https://api.github.com/repos/$REPOSITORY/releases/latest"
DOWNLOAD_DIR="/tmp/ledcontrol-package.$$"
PACKAGES="ledcontrol luci-app-ledcontrol luci-i18n-ledcontrol-ru"

msg() {
	printf '%s\n' "ledcontrol: $*"
}

die() {
	msg "$*" >&2
	exit 1
}

cleanup() {
	rm -rf "$DOWNLOAD_DIR"
}

get_release_line() {
	[ -r /etc/openwrt_release ] || die 'cannot read /etc/openwrt_release'
	version=$(sed -n "s/^DISTRIB_RELEASE='\([^']*\)'$/\1/p" /etc/openwrt_release)

	case "$version" in
		25.12*) release_line=25.12 ;;
		24.10*) release_line=24.10 ;;
		23.05*) release_line=23.05 ;;
		*) die "OpenWrt $version is not supported (supported: 25.12, 24.10, 23.05)" ;;
	esac
}

select_package_manager() {
	if command -v apk >/dev/null 2>&1; then
		[ "$release_line" = 25.12 ] || die "apk is unexpected on OpenWrt $release_line"
		package_extension=apk
		return
	fi

	if command -v opkg >/dev/null 2>&1; then
		[ "$release_line" != 25.12 ] || die "opkg is unexpected on OpenWrt $release_line"
		package_extension=ipk
		return
	fi

	die 'neither apk nor opkg is available'
}

download_packages() {
	release_urls=$(wget -qO- "$RELEASE_API" | \
		sed -n 's/.*"browser_download_url": "\([^"]*\)".*/\1/p') || \
		die 'cannot retrieve the latest GitHub release'
	[ -n "$release_urls" ] || die 'the latest GitHub release has no downloadable assets'

	mkdir -p "$DOWNLOAD_DIR" || die 'cannot create a temporary directory'

	for package in $PACKAGES; do
		asset_url=""
		for url in $release_urls; do
			case "${url##*/}" in
				"$package"_*"-openwrt-$release_line.$package_extension")
					asset_url=$url
					break
					;;
			esac
		done

		[ -n "$asset_url" ] || die "release does not contain $package for OpenWrt $release_line"
		msg "downloading ${asset_url##*/}"
		wget -q -O "$DOWNLOAD_DIR/$package.$package_extension" "$asset_url" || \
			die "failed to download $package"
		[ -s "$DOWNLOAD_DIR/$package.$package_extension" ] || die "downloaded $package is empty"
	done
}

install_packages() {
	msg "installing packages for OpenWrt $release_line"
	if [ "$package_extension" = apk ]; then
		apk add --allow-untrusted "$DOWNLOAD_DIR"/*.apk
	else
		opkg update
		opkg install "$DOWNLOAD_DIR"/*.ipk
	fi
}

[ "$(id -u)" = 0 ] || die 'run this installer as root'
trap cleanup EXIT HUP INT TERM
get_release_line
select_package_manager
download_packages
install_packages
msg 'installation completed'
