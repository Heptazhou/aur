# Maintainer: Heptazhou <zhou at 0h7z dot com>

pkgbase_=iraf
pkgname_=($pkgbase_{,-noao})
pkgname=(${pkgname_[@]/%/-bin})
debver=2.17.1-5
pkgver=2.17.1
pkgrel=3
pkgdesc="IRAF - Image Reduction and Analysis Facility"
arch=("x86_64")
url="https://github.com/iraf-community/$pkgbase_"
url_="https://deb.debian.org/debian/pool/main/i/$pkgbase_"
license=("custom")
options=(!debug)
noextract=(${pkgname_[@]/%/_${debver}_amd64.deb})
source=(${noextract[@]/#/${url_}/})
sha256sums=(
	"72122b4274fe2db881f3ac0a9da226ba0498570311dc83efe571fd44a7df0226"
	"4520541e76cb2d5bf4fc8e6f84efe233581798526b230aec5624b4672f7a1570"
)
# https://tracker.debian.org/pkg/iraf

prepare() {
	for name in "${pkgname_[@]}"; do
		ar x "${name}_${debver}_amd64.deb" "data.tar.xz"
		mkdir "$name/" -p
		tar Cfx "$name" "data.tar.xz" && rm "data.tar.xz"
	done
}

package_iraf-bin() {
	provides=("$pkgbase_")
	conflicts=("$pkgbase_")
	depends=("bash" "cfitsio" "expat")
	optdepends=(
		"$pkgbase_-noao: IRAF NOAO data reduction package"
		"ds9: Image display tool for astronomy"
		"xgterm: Terminal emulator to work with IRAF"
	)

	cd -- "$srcdir/$pkgbase_/"

	mkdir "usr/share/licenses/$pkgbase_/" -p
	mv -T "usr/share"/{"doc/$pkgbase_/copyright","licenses/$pkgbase_/LICENSE"}
	rm -r "usr/share"/{"doc","lintian"} -f
	cp -t "$pkgdir/" -a "usr" "etc"
}

package_iraf-noao-bin() {
	provides=("$pkgbase_-noao")
	conflicts=("$pkgbase_-noao")
	depends=("$pkgbase_")

	cd -- "$srcdir/$pkgbase_-noao/"

	mkdir "usr/share/licenses/" -p
	ln -s "usr/share/licenses/$pkgbase_"{,-noao}
	rm -r "usr/share"/{"doc","lintian"} -f
	cp -t "$pkgdir/" -a "usr"
}
