# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4
JAVA_PKG_IUSE="doc examples"
inherit eutils java-pkg-2 autotools fdo-mime

DESCRIPTION="Java interface to the HDF5 library"
HOMEPAGE="http://www.hdfgroup.org/hdf-java-html/inxodex.html"
SRC_URI="http://www.hdfgroup.org/ftp/HDF5/hdf-java/src/${P}-src.tar"

LICENSE="NCSA-HDF"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="hdf hdfview szip test zlib"

CDEPEND=">=sci-libs/hdf5-1.8[szip=,zlib=]
	hdf? ( sci-libs/hdf virtual/jpeg )
	hdfview? ( dev-java/fits dev-java/netcdf )"

RDEPEND="${CDEPEND}
	>=virtual/jre-1.5"

DEPEND="${CDEPEND}
	>=virtual/jdk-1.5
	test? ( >=dev-java/junit-4 )"

REQUIRED_USE="hdfview? ( hdf )"

# buggy test with incompatible hdf5 library versions
RESTRICT="test"

S="${WORKDIR}/${PN}"

src_prepare() {
	epatch "${FILESDIR}"/${P}-shared.patch
	eautoreconf
	rm lib/*.jar
	if hdfview; then
		java-pkg_jar-from --into lib fits fits.jar
		java-pkg_jar-from --into lib netcdf netcdf.jar
	fi
	use test && java-pkg_jar-from --into lib junit-4 junit.jar
}

src_configure() {
	local stdpath="${EPREFIX}/usr/include,${EPREFIX}/usr/$(get_libdir)"
	local myconf="--with-hdf4=no --with-libjpeg=no"
	use hdf && \
		myconf="--with-libjpeg=${stdpath} --with-hdf4=${stdpath}"
	use zlib &&	myconf="${myconf} --with-libz=\"${stdpath}\""
	use szip && myconf="${myconf} --with-libsz=\"${stdpath}\""

	econf \
		${myconf} \
		--with-hdf5="${stdpath}" \
		--with-jdk="$(java-config -o)/include,$(java-config -o)/jre/lib"
}

src_compile() {
	# parallel needs work. anyone?
	emake -j1 ncsa just-hdf5

	if use hdf; then
		sed -i \
			-e "s/MAX_VAR_DIMS/H4_MAX_VAR_DIMS/" \
			native/hdflib/hdfstructsutil.c || die
		sed -i \
			-e "s/MAX_NC_NAME/H4_MAX_NC_NAME/" \
			native/hdflib/hdf{vdata,sds}Imp.c || die
		emake -j1 just-hdf4
	fi

	use hdfview && emake -j1
	use examples && emake -j1 do-examples
	use doc && emake -j1 javadocs
}

src_test() {
	emake -j1 check
}

src_install() {
	java-pkg_dojar lib/jhdf5.jar
	java-pkg_doso lib/linux/libjhdf5.so

	if use hdf; then
		java-pkg_dojar lib/jhdf.jar
		java-pkg_doso lib/linux/libjhdf.so
	fi

	if use hdfview; then
		java-pkg_dojar lib/jhdf5obj.jar
		java-pkg_dojar lib/jhdfobj.jar
		java-pkg_dojar lib/ext/nc2obj.jar
		java-pkg_dojar lib/ext/fitsobj.jar
		java-pkg_dojar lib/jhdfview.jar
		cat <<-EOF > hdfview
			export CLASSPATH=\$(java-config --classpath hdf-java)
			\$(java-config --java) \
				-Xmx1000m \
				-Djava.library.path=\"\$(java-config --library hdf-java)\" \
				ncsa.hdf.view.HDFView \
				-root "${EROOT}" \$*
		EOF
		dobin hdfview
		insinto /usr/share/mime/packages
		doins "${FILESDIR}"/hdfview.xml
		newicon ncsa/hdf/view/icons/hdf_large.gif hdfview.gif
		make_desktop_entry hdfview "HDF Viewer" hdfview
	fi

	use doc && java-pkg_dojavadoc docs/javadocs
	use examples && java-pkg_doexamples examples
}

pkg_postinst() {
	use hdfview && fdo-mime_desktop_database_update
}

pkg_postrm() {
	use hdfview && fdo-mime_desktop_database_update
}