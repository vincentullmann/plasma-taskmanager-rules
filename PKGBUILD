# Maintainer: Vincent Ullmann
# Local build: run `makepkg -si` in this directory (rebuild after Plasma upgrades).
pkgname=plasma-taskmanager-rules
pkgver=0.1.0
pkgrel=1
pkgdesc='Minimal rule-based Plasma 6 task manager'
arch=(x86_64)
url='https://github.com/vincentullmann/plasma-taskmanager-rules'
license=(GPL-2.0-or-later)
depends=(plasma-workspace libplasma qt6-declarative)
makedepends=(cmake extra-cmake-modules ninja)
options=(!debug)

build() {
  cmake -S "$startdir" -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr
  cmake --build build
}

check() {
  node --test "$startdir/js"
}

package() {
  DESTDIR="$pkgdir" cmake --install build
}
