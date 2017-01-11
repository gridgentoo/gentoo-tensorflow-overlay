# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit git-r3 cmake-utils toolchain-funcs

DESCRIPTION="A very simple camera interface (frame grabber) for Torch7."
HOMEPAGE="https://github.com/torch/qtlua"
EGIT_REPO_URI="https://github.com/torch/qtlua.git"

LICENSE="BSD3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="doc +luajit"
FEATURES="keeptemp keepwork"

COMMON_DEPEND="!luajit? ( >=dev-lang/lua-5.1:= )
				luajit? ( dev-lang/luajit:2= )"
DEPEND="${COMMON_DEPEND}
		virtual/pkgconfig"
RDEPEND="${COMMON_DEPEND} ${DEPEND}"

src_configure() {
	local mycmakeargs=(
		"-DLUADIR=$($(tc-getPKG_CONFIG) --variable INSTALL_LMOD $(usex luajit 'luajit' 'lua'))"
		"-DLIBDIR=$($(tc-getPKG_CONFIG) --variable INSTALL_LIB $(usex luajit 'luajit' 'lua'))"
		"-DLUA_BINDIR=$($(tc-getPKG_CONFIG) --variable INSTALL_BIN $(usex luajit 'luajit' 'lua'))"
		"-DLUA_INCDIR=$($(tc-getPKG_CONFIG) --variable INSTALL_INC $(usex luajit 'luajit' 'lua'))"
		"-DLUA_LIBDIR=$($(tc-getPKG_CONFIG) --variable INSTALL_CMOD $(usex luajit 'luajit' 'lua'))"
		"-DSCRIPTS_DIR=$($(tc-getPKG_CONFIG) --variable INSTALL_BIN $(usex luajit 'luajit' 'lua'))"
		"-DLUALIB=`equery files luajit |grep lib64/libluajit | grep .so | awk 'NR==0; END{print}'`"
		"-DLUA=/usr/bin/luajit"
		"-DQT_INSTALL_LIBRARIES=ON"
		"-DQtLua_INSTALL_INCLUDE=$($(tc-getPKG_CONFIG) --variable INSTALL_INC $(usex luajit 'luajit' 'lua'))"
		"-DQtLua_INSTALL_BIN_SUBDIR=$($(tc-getPKG_CONFIG) --variable INSTALL_BIN $(usex luajit 'luajit' 'lua'))"
		"-DQtLua_INSTALL_LIB=$($(tc-getPKG_CONFIG) --variable INSTALL_BIN $(usex luajit 'luajit' 'lua'))"
		"-DQtLua_INSTALL_LIB_SUBDIR=$($(tc-getPKG_CONFIG) --variable INSTALL_CMOD $(usex luajit 'luajit' 'lua'))"
	)
	cmake-utils_src_configure
}


src_compile() {
	elog "===================== COMPILE PHASE"
	cmake-utils_src_compile
	elog ${WORKDIR}
	elog ${S}
	 #* /tmp/portage/dev-lua/torch-qtlua-9999/work
 	#* /tmp/portage/dev-lua/torch-qtlua-9999/work/torch-qtlua-9999

	mkdir -p "${D}"/usr/lib/lua/5.1 "${D}"/usr/share/lua/5.1/
	mv "${S}"/*.so "${D}"/usr/lib/lua/5.1/
	mv /tmp/portage/dev-lua/torch-qtlua-9999/work/torch-qtlua-9999/libqtcore.so /root
    mv "${D}"/usr/lib/*.so "${D}"/usr/lib/lua/5.1/
}
src_install() {
	elog "===================== INSTALL PHASE"
	cmake-utils_src_install
	mkdir -p "${D}"/usr/lib/lua/5.1 "${D}"/usr/share/lua/5.1/
	
	mv "${S}"/*.so "${D}"/usr/lib/lua/5.1/
    mv "${S}"/usr/lib/*.so "${D}"/usr/lib/lua/5.1/
    mv "${D}"/usr/lua/* "${D}"/usr/share/lua/5.1/
    rm -rf "${D}"/usr/lua
}


