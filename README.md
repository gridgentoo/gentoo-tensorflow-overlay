№ Experimental Gentoo overlay with primary focus on AI frameworks, GPU acceleration, BigData and high-performance Java.

* ebuilds  tensorflow  для Gentoo. Установка  tensorflow в Gentoo 

https://github.com/gridgentoo/gentoo-tensorflow-overlay/blob/master/ai-frameworks/tensorflow/tensorflow-9999.ebuild

```
# Copyright 2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
PYTHON_COMPAT=( python{2_7,3_4,3_5,3_6} pypy )

inherit eutils multiprocessing distutils-r1 git-r3

DESCRIPTION="Library for Machine Intelligence"

HOMEPAGE="https://www.tensorflow.org/"
SRC_URI=""
EGIT_REPO_URI="https://github.com/tensorflow/tensorflow"
#EGIT_COMMIT="c9568f1ee51a265db4c5f017baf722b9ea5ecfbb"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm ~hppa ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd ~amd64-linux ~x86-linux ~x86-macos"
IUSE="amazon-s3 cuda gdr google-cloud hadoop malloc opencl verbs xla-jit"
RESTRICT="primaryuri"

RDEPEND="
	>=dev-python/numpy-1.11.2-r1
	>=dev-python/six-1.10.0
	cuda? (
    >=dev-libs/nvidia-cuda-cudnn-7.0
	  >=dev-util/nvidia-cuda-toolkit-9.0.176
          >=x11-drivers/nvidia-drivers-387.34
        )
"

DEPEND="
	dev-python/setuptools
	>=dev-util/bazel-0.7.0[tools]
	>=virtual/jdk-1.8.0-r3
	>=dev-python/markdown-2.6.9
	>=dev-python/werkzeug-0.12.2
	>=dev-python/bleach-1.5.0
	>=dev-python/protobuf-python-3.4.1
	>=dev-python/pip-9.0.1-r1
	>=dev-python/wheel-0.29.0
	>=dev-lang/swig-3.0.12
	>=dev-python/absl-py-0.1.4
	${RDEPEND}
"

#src_prepare() {
	#sed -i -e 's/protobuf == 3.0.0a3/protobuf >= 2.6.0/g' \
	#tensorflow/tools/pip_package/setup.py
#}

src_configure() {
	export CUDNN_INSTALL_PATH="/usr/lib64"
	export TF_NEED_CUDA="1"
	export TF_CUDA_VERSION="9.0"
	export TF_CUDNN_VERSION="7"
	yes "" | ./configure

	cat > CROSSTOOL << EOF
tool_path {
	name: "gcc"
	path: "${CC}"
}
tool_path {
	name: "g++"
	path: "${CXX}"
EOF

	echo "Will build with $(makeopts_jobs) jobs"

}

src_compile() {
	addwrite /proc/self
	# Added from bazel ebuild.. I am blind here as I don't understand deeply bazel itself :-)
	addpredict /proc

	# Add /proc/self to avoid a sandbox breakage
	local -x SANDBOX_WRITE="${SANDBOX_WRITE}"
	echo "SANDBOX_WRITE=$SANDBOX_WRITE"

	cat > bazelrc << EOF
startup --batch
build --spawn_strategy=standalone --genrule_strategy=standalone
build --jobs $(makeopts_jobs)
EOF
	export BAZELRC="$PWD/bazelrc"
	elog "Compile Phase - Bazel configured"
	bazel build \
	 --spawn_strategy=standalone --genrule_strategy=standalone \
	 --config=opt --config=cuda //tensorflow/tools/pip_package:build_pip_package
	 elog "Compile Phase - Bazel build finished"
}

src_install() {
	bazel-bin/tensorflow/tools/pip_package/build_pip_package "$PWD/tensorflow_pkg"
	local TENSORFLOW_WHEEL_FILE="$(find $PWD/tensorflow_pkg/tensorflow* -type f -exec sh -c 'echo $(basename {})' \;)"
	pip install --root "${ED}" "$PWD/tensorflow_pkg/$TENSORFLOW_WHEEL_FILE"
	rm -rf "${ED}"/usr/lib*/python*/site-packages/google/protobuf
}
```


* ebuilds  Caffe для Gentoo. Установка Caffe в Gentoo : : BigdataOverlay

https://github.com/gridgentoo/GentooCaffe/blob/master/dev-libs/caffe/caffe-9999.ebuild

* ebuilds hadoop для Gentoo

emerge sys-cluster/apache-hadoop-bin

https://github.com/gridgentoo/GentooHadoop/blob/master/portage/sys-cluster/apache-hadoop-bin/apache-hadoop-bin-2.7.1.ebuild

* ebuilds Spark для Gentoo

emerge sys-cluster/apache-spark-bin

https://github.com/gridgentoo/gentoo-tensorflow-overlay/blob/master/sys-cluster/apache-spark-bin/apache-spark-bin-2.1.1.ebuild

* ebuilds Zookeeper для Gentoo
https://github.com/gridgentoo/gentoo-tensorflow-overlay/blob/master/sys-cluster/apache-zookeeper-bin/apache-zookeeper-bin-3.4.10.ebuild

```
# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
PYTHON_COMPAT=( python2_7 )

inherit distutils-r1 eutils java-utils-2 user

MY_P="zookeeper"
MY_PN=${MY_P}-${PV}

DESCRIPTION="A high-performance coordination service for distributed applications."
HOMEPAGE="http://zookeeper.apache.org/"
SRC_URI="mirror://apache/${MY_P}/${MY_PN}/${MY_PN}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
RESTRICT="mirror binchecks"
IUSE=""

DEPEND=""
RDEPEND=">=virtual/jre-1.7"

S=${WORKDIR}/${MY_PN}

INSTALL_DIR=/opt/${PN}
export CONFIG_PROTECT="${CONFIG_PROTECT} ${INSTALL_DIR}/conf"

pkg_setup() {
	enewgroup zookeeper
	enewuser zookeeper -1 /bin/sh /var/lib/zookeeper zookeeper
}

src_prepare() {
	# python
	sed -e "s|src/c/zookeeper.c|zookeeper.c|g" \
		-e "s|../../../|${S}|g" \
		-i contrib/zkpython/src/python/setup.py || die
}

src_configure() {
	cd "${S}"/src/c || die
	econf
}

src_compile() {
	cd "${S}"/src/c || die
	emake
}

src_install() {
	local DATA_DIR=/var/lib/${MY_P}

	# python
	cd "${S}"/contrib/zkpython/ || die
	mv src/python/setup.py .
	mv src/c/* .
	python_foreach_impl distutils-r1_src_install
	cd "${S}" || die

	# cleanup sources
	rm -rf src/ || die
	rm bin/*.cmd || die

	keepdir "${DATA_DIR}"
	sed "s:^dataDir=.*:dataDir=${DATA_DIR}:" conf/zoo_sample.cfg > conf/zoo.cfg || die "sed failed"
	cp "${FILESDIR}"/log4j.properties conf/ || die "cp log4j conf failed"

	dodir "${INSTALL_DIR}"
	cp -a "${S}"/* "${D}${INSTALL_DIR}" || die "install failed"

	# data dir perms
	fowners zookeeper:zookeeper "${DATA_DIR}"

	# log dir
	keepdir /var/log/zookeeper
	fowners zookeeper:zookeeper /var/log/zookeeper

	# init script
	newinitd "${FILESDIR}"/zookeeper.initd zookeeper
	newconfd "${FILESDIR}"/zookeeper.confd zookeeper

	# env file
	cat > 99"${PN}" <<-EOF
		PATH=${INSTALL_DIR}/bin
		CONFIG_PROTECT=${INSTALL_DIR}/conf
	EOF
	doenvd 99"${PN}" || die "doenvd failed"
}
```
