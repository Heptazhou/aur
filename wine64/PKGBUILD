# Maintainer: Heptazhou <zhou at 0h7z dot com>

# Maintainer: Daniele Basso <d dot bass05 at proton dot me>

## useful links:
# https://www.winehq.org
# https://gitlab.winehq.org/wine/wine
# https://gitlab.winehq.org/wine/wine-staging
# https://github.com/wine-staging/wine-staging

pkgname=wine64 # wine-wow64
pkgver=9.5
_pkgver="${pkgver/rc/-rc}"
pkgrel=1
pkgdesc="A compatibility layer for running Windows programs"
url="https://www.winehq.org"
license=(LGPL)
arch=(x86_64)

depends=(
	alsa-plugins
	fontconfig
	freetype2
	gettext
	gst-plugins-base-libs
	libpulse
	libxcomposite
	libxcursor
	libxi
	libxinerama
	libxrandr
	opencl-icd-loader
	pcsclite
	sdl2
	v4l-utils
	desktop-file-utils
	libgphoto2
)
_spacehogs=(
	samba
	sane
)
makedepends=(
	libcups
	libxxf86vm
	mesa
	mesa-libgl
	vulkan-icd-loader
	autoconf
	bison
	flex
	mingw-w64-gcc
	opencl-headers
	perl
	vulkan-headers

	"${_spacehogs[@]}"
)
optdepends=(
	alsa-lib
	cups
	dosbox

	"${_spacehogs[@]}"
)

provides=("wine=$pkgver")
conflicts=("wine")

install="wine.install"
backup=("usr/lib/binfmt.d/wine.conf")

options=(staticlibs strip !debug !lto)

source=(
	"https://dl.winehq.org/wine/source/${pkgver::1}.x/wine-$_pkgver.tar.xz"
	"30-win32-aliases.conf"
	"wine-binfmt.conf"
)
b2sums=(
	"c14ebf02f0f5b91bc2b2517ff3630f22c6af7fdc827c5d024d809a383a65446284a5349c8109835112f5353f361088f4f32de1a3d04299fbf39deacbc0e8e8bf"
	"45db34fb35a679dc191b4119603eba37b8008326bd4f7d6bd422fbbb2a74b675bdbc9f0cc6995ed0c564cf088b7ecd9fbe2d06d42ff8a4464828f3c4f188075b"
	"e9de76a32493c601ab32bde28a2c8f8aded12978057159dd9bf35eefbf82f2389a4d5e30170218956101331cf3e7452ae82ad0db6aad623651b0cc2174a61588"
)

build() {
	cd "wine-$_pkgver"
	./configure \
		--disable-tests \
		--prefix=/usr \
		--libdir=/usr/lib \
		\
		--enable-archs=x86_64
	make
}

package() {
	cd "wine-$_pkgver"
	make prefix="$pkgdir"/usr \
		libdir="$pkgdir"/usr/lib \
		dlldir="$pkgdir"/usr/lib/wine install

	ln -s "$pkgdir"/usr/bin/wine{64,} -r

	# Font aliasing settings for Win32 applications
	install -Dm644 "$srcdir"/30-win32-aliases.conf -t "$pkgdir"/usr/share/fontconfig/conf.avail/
	install -d "$pkgdir"/usr/share/fontconfig/conf.default
	ln -s ../conf.avail/30-win32-aliases.conf "$pkgdir"/usr/share/fontconfig/conf.default/30-win32-aliases.conf

	x86_64-w64-mingw32-strip --strip-unneeded "$pkgdir"/usr/lib/wine/x86_64-windows/*.dll

	install -Dm644 "$srcdir"/wine-binfmt.conf "$pkgdir"/usr/lib/binfmt.d/wine.conf
}
