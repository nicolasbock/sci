# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

DESCRIPTION="TrajNG - Trajectory compression library"
HOMEPAGE="http://www.uppmax.uu.se/Members/daniels/trajng-trajectory-compression-library"
SRC_URI="http://www.uppmax.uu.se/Members/daniels/trajng-trajectory-compression-library/${P}.tar.gz"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="~amd64 ~amd64-linux ~x86-linux"
IUSE="fortran mpi"

DEPEND="
	sci-chemistry/xdrfile
	fortran? ( virtual/fortran )
	mpi? ( virtual/mpi )
"
RDEPEND="${DEPEND}"

src_prepare() {
	rm -rf "${S}/xdrfile" || die
}

src_configure() {
	econf \
		--with-xdrlib="${EPREFIX}/usr" \
		$(use_enable fortran) \
		$(use_enable mpi)
}