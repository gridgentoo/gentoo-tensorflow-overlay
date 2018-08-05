# Experimental Gentoo overlay with primary focus on AI frameworks, GPU acceleration, BigData and high-performance Java.

Apache Mesos — это централизованная отказоустойчивая система управления кластером, разработанная для распределенных компьютерных сред c целью обеспечения изоляции ресурсов и удобного управления кластерами подчиненных узлов

![Image alt](https://clouddocs.f5.com/training/community/containers/html/_images/Mesos_Architecture.png)

* ebuilds  Apache Mesos  для Gentoo. Установка  Apache Mesos в Gentoo 

https://github.com/gridgentoo/gentoo-tensorflow-overlay/blob/master/sys-cluster/mesos/mesos-1.5.0.ebuild

```
# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit autotools eutils

MY_P="mesos"
MY_PN=${MY_P}-${PV}
DESCRIPTION="A cluster manager that provides efficient resource isolation and sharing across distributed applications"
HOMEPAGE="http://mesos.apache.org/"
SRC_URI="http://archive.apache.org/dist/${PN}/${PV}/${P}.tar.gz"
#SRC_URI="mirror://apache/${MY_P}/${MY_PN}/${MY_PN}.tar.gz"
LICENSE="Apache-2.0"
KEYWORDS="~amd64 ~x86"
IUSE="network-isolator perftools install-module-dependencies"
SLOT="0"

# dev-libs/libnl-3.2.28 lot of changes occured from 1.2 and previous versions
# whole ebuild need review.
RDEPEND=">=dev-libs/apr-1.5.2
	>=net-misc/curl-7.43.0
	>=dev-libs/libnl-3.2.28
	network-isolator? ( dev-libs/libnl )
	dev-libs/cyrus-sasl
	>=dev-vcs/subversion-1.9.4"
DEPEND=$RDEPEND

S=${WORKDIR}/${MY_PN}

src_prepare() {
	echo `pwd`
	#epatch "${FILESDIR}/mesos-stout-cloexec.patch"
	#epatch "${FILESDIR}/mesos-linux-ns-nosetns.patch"
	eautoreconf
}

src_configure() {
	# See https://issues.apache.org/jira/browse/MESOS-7286
	MESOS_LIB_PREFIX="${EPREFIX}/usr"
	export SASL_PATH="${MESOS_LIB_PREFIX}/lib/sasl2"
	export LD_LIBRARY_PATH="${MESOS_LIB_PREFIX}/lib:$LD_LIBRARY_PATH"
	econf --build=x86_64-pc-linux-gnu --host=x86_64-pc-linux-gnu \
		$(use_enable perftools) \
		$(use_enable install-module-dependencies) \
		$(use_with network-isolator) \
		$(use_with network-isolator nl "${MESOS_LIB_PREFIX}") \
		--disable-python \
		--disable-java \
		--enable-optimize \
		--disable-dependency-tracking \
		--with-apr=${MESOS_LIB_PREFIX} \
		--with-curl=${MESOS_LIB_PREFIX} \
		--with-sasl=${MESOS_LIB_PREFIX} \
		--with-svn=${MESOS_LIB_PREFIX}
}

src_compile() {
	emake
}

src_test() {
	emake check
}

src_install() {
	emake DESTDIR="${D}" install
}
```

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


* ebuilds Spark для Gentoo

emerge sys-cluster/apache-spark-bin

https://github.com/gridgentoo/gentoo-tensorflow-overlay/blob/master/sys-cluster/apache-spark-bin/apache-spark-bin-2.1.1.ebuild

```
# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"
inherit user

MY_PN="spark"

DESCRIPTION="Software framework for fast cluster computing"
HOMEPAGE="http://spark.apache.org/"
SRC_URI="mirror://apache/${MY_PN}/${MY_PN}-${PV}/${MY_PN}-${PV}-bin-hadoop2.7.tgz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="scala"

DEPEND="scala? ( dev-lang/scala )"

RDEPEND="virtual/jre
scala? ( dev-lang/scala )"

S="${WORKDIR}/${MY_PN}-${PV}-bin-hadoop2.7"
INSTALL_DIR=/opt/${MY_PN}-${PV}

pkg_setup(){
	enewgroup hadoop
	enewuser spark -1 /bin/bash /home/spark hadoop
}

src_install() {
	sandbox=`egrep -c "^[0-9].*#.* sandbox" /etc/hosts`
	workmem=1024m
	[ $sandbox -ne 0 ] && workmem=192m

	# create file spark-env.sh
	cat > conf/spark-env.sh <<-EOF
SPARK_LOG_DIR=/var/log/spark
SPARK_PID_DIR=/var/run/pids
SPARK_LOCAL_DIRS=/var/lib/spark
SPARK_WORKER_MEMORY=${workmem}
SPARK_WORKER_DIR=/var/lib/spark
EOF

	dodir "${INSTALL_DIR}"
	diropts -m770 -o spark -g hadoop
	dodir /var/log/spark
	dodir /var/lib/spark
	rm -f bin/*.cmd
	# dobin bin/*
	fperms g+w conf/*
	mv "${S}"/* "${D}${INSTALL_DIR}"
	fowners -Rf root:hadoop "${INSTALL_DIR}"

	# conf symlink
	dosym ${INSTALL_DIR}/conf /etc/spark

	cat > 99spark <<EOF
SPARK_HOME="${INSTALL_DIR}"
SPARK_CONF_DIR="/etc/spark"
PATH="${INSTALL_DIR}/bin"
EOF
	doenvd 99spark

	# init scripts
	newinitd "${FILESDIR}"/"${MY_PN}.init" "${MY_PN}.init"
	dosym  /etc/init.d/"${MY_PN}.init" /etc/init.d/"${MY_PN}-worker"
	if [ `egrep -c "^[0-9].*${HOSTNAME}.*#.* sparkmaster" /etc/hosts` -eq 1 ] ; then
		dosym  /etc/init.d/"${MY_PN}.init" /etc/init.d/"${MY_PN}-master"
	fi
	dosym "${INSTALL_DIR}" "/opt/${MY_PN}"
}
```

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
* ebuilds  Caffe для Gentoo. Установка Caffe в Gentoo : : BigdataOverlay

https://github.com/gridgentoo/GentooCaffe/blob/master/dev-libs/caffe/caffe-9999.ebuild

```
# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

#EGIT_REPO_URI="git://github.com/BVLC/caffe.git"
EGIT_REPO_URI="git://github.com/NVIDIA/caffe"
PYTHON_COMPAT=( python2_7 )

inherit toolchain-funcs multilib git-r3 python-single-r1
# Can't use cuda.eclass as nvcc does not like --compiler-bindir set there for some reason

DESCRIPTION="Deep learning framework by the BVLC"
HOMEPAGE="http://caffe.berkeleyvision.org/"
SRC_URI=""

LICENSE="BSD-2"
SLOT="0"
KEYWORDS=""
IUSE="cuda python"

CDEPEND="
	dev-libs/boost:=[python?]
	media-libs/opencv:=
	dev-libs/protobuf:=[python?]
	dev-cpp/glog:=
	dev-cpp/gflags:=
	sci-libs/hdf5:=
	dev-libs/leveldb:=
	app-arch/snappy:=
	dev-db/lmdb:=
	cuda? (
		dev-util/nvidia-cuda-toolkit
	)
	python? (
		${PYTHON_DEPS}
	)
"
DEPEND="
	${CDEPEND}
	sys-devel/bc
"
RDEPEND="
	${CDEPEND}
	python? (
		dev-python/pandas[${PYTHON_USEDEP}]
		dev-python/numpy[${PYTHON_USEDEP}]
		media-gfx/pydot[${PYTHON_USEDEP}]
		sci-libs/scikits_image[${PYTHON_USEDEP}]
	)
"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

pkg_setup() {
	python-single-r1_pkg_setup
}

src_configure() {
	# Respect CFLAGS
	sed -e '/COMMON_FLAGS/s/-O2//' -i Makefile

	cat > Makefile.config << EOF
BLAS := atlas
BUILD_DIR := build
DISTRIBUTE_DIR := distribute
USE_PKG_CONFIG := 1
LIBRARY_NAME_SUFFIX := -nv
EOF

	if use cuda; then
		cat >> Makefile.config << EOF
CUDA_DIR := "${EPREFIX}/opt/cuda"
CUDA_ARCH := -gencode arch=compute_20,code=sm_20 \
			 -gencode arch=compute_20,code=sm_21 \
			 -gencode arch=compute_30,code=sm_30 \
			 -gencode arch=compute_35,code=sm_35 \
			 -gencode arch=compute_50,code=sm_50 \
			 -gencode arch=compute_50,code=compute_50
EOF

		# This should be handled by Makefile itself, but somehow is broken
		sed -e "/CUDA_LIB_DIR/s/lib/$(get_libdir)/" -i Makefile || die "sed failed"
	else
		echo "CPU_ONLY := 1" >> Makefile.config
	fi

	if use python; then
		python_export PYTHON_INCLUDEDIR PYTHON_SITEDIR PYTHON_LIBPATH
		cat >> Makefile.config << EOF
PYTHON_INCLUDE := "${PYTHON_INCLUDEDIR}" "${PYTHON_SITEDIR}/numpy/core/include"
PYTHON_LIB := "$(dirname ${PYTHON_LIBPATH})"
WITH_PYTHON_LAYER := 1
INCLUDE_DIRS += \$(PYTHON_INCLUDE)
LIBRARY_DIRS += \$(PYTHON_LIB)
EOF

		local py_version=${EPYTHON#python}
		sed -e "/PYTHON_LIBRARIES/s/python\s/python-${py_version} /g" \
			-i Makefile || die "sed failed"
	fi

	sed -e '/blas/s/atlas//' \
		-e '/^LINKFLAGS +=/ a\
		LINKFLAGS += -L$(LIB_BUILD_DIR)
		' \
		-i Makefile || die "sed failed"

	tc-export CC CXX
}

src_compile() {
	emake

	use python && emake pycaffe
}

src_test() {
	emake runtest

	use python && emake pytest
}

src_install() {
	emake distribute

	for bin in distribute/bin/*; do
		local name=$(basename ${bin})
		newbin ${bin} ${name//.bin/}
	done

	insinto /usr
	doins -r distribute/include/

	dolib.a distribute/lib/libcaffe*.a*
	dolib.so distribute/lib/libcaffe*.so*

	if use python; then
		rm distribute/python/caffe/_caffe.cpp || die "rm failed"
		python_domodule distribute/python/caffe
		for script in distribute/python/*.py; do
			python_doscript ${script}
		done
	fi
}
```

* ebuilds hadoop для Gentoo

emerge sys-cluster/apache-hadoop-bin

https://github.com/gridgentoo/GentooHadoop/blob/master/portage/sys-cluster/apache-hadoop-bin/apache-hadoop-bin-2.7.1.ebuild

```
# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="5"
inherit user

MY_PN="hadoop"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Software framework for data intensive distributed applications"
HOMEPAGE="http://hadoop.apache.org/"
SRC_URI="mirror://apache/hadoop/common/${MY_P}/${MY_P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND=""
RDEPEND="virtual/jre
net-misc/openssh"

S=${WORKDIR}/${MY_P}
INSTALL_DIR=/opt/${MY_P}

pkg_setup(){
	enewgroup hadoop
	enewuser hdfs -1 /bin/bash /home/hdfs hadoop
	enewuser yarn -1 /bin/bash /home/yarn hadoop
	enewuser mapred -1 /bin/bash /home/mapred hadoop
}

src_install() {
	# get the cluster topology from /etc/hosts
	hostname=`uname -n`
	namenode=`egrep "^[0-9].*#.* namenode" /etc/hosts | awk '{print $2}' `
	[[ -n $namenode ]] || namenode=$hostname
	secondary=`egrep "^[0-9].*#.* secondaryname" /etc/hosts | awk '{print $2}'`
	[[ -n $secondary ]] || secondary=$hostname
	resmgr=`egrep "^[0-9].*#.* resourcemanager" /etc/hosts | awk '{print $2}'`
	[[ -n $resmgr ]] || resmgr=$hostname
	histsrv=`egrep "^[0-9].*#.* historyserver" /etc/hosts | awk '{print $2}'`
	[[ -n $histsrv ]] || histsrv=$hostname

	sandbox=`egrep -c "^[0-9].*#.* sandbox" /etc/hosts`
	replication=`egrep -c "^[0-9].*#.* datanode" /etc/hosts`
	[ $replication -gt 3 ] && replication=3
	if [ $replication -eq 0 ]; then
		if [ $sandbox -ne 0 ]; then
			replication=1
		else replication=3
		fi
	fi
	javaheap=1024
	[ $sandbox -ne 0 ] && javaheap=192

	# hadoop-env.sh
	cat >tmpfile<<EOF
export JAVA_HOME=$(java-config -g JAVA_HOME)
export HADOOP_PID_DIR=/var/run/pids
export HADOOP_LOG_DIR=/var/log/hadoop
export HADOOP_HEAPSIZE=$javaheap
EOF
	sed -i '/# Set Hadoop-specific/r tmpfile' etc/hadoop/hadoop-env.sh || die

	# yarn-env.sh
	cat >tmpfile<<EOF
export JAVA_HOME=$(java-config -g JAVA_HOME)
export YARN_CONF_DIR=/etc/hadoop
export YARN_LOG_DIR=/var/log/hadoop
export YARN_PID_DIR=/var/run/pids
export YARN_HEAPSIZE=$javaheap
EOF
	sed -i "/# limitations under the/r tmpfile"  etc/hadoop/yarn-env.sh || die

	# mapred-env.sh
	cat >tmpfile<<EOF
export JAVA_HOME=$(java-config -g JAVA_HOME)
export HADOOP_MAPRED_LOG_DIR=/var/log/hadoop
export HADOOP_MAPRED_PID_DIR=/var/run/pids
export HADOOP_JOB_HISTORYSERVER_HEAPSIZE=$javaheap
EOF
	cat tmpfile >>etc/hadoop/mapred-env.sh || die

	# core-site.xml
	cat >tmpfile<<EOF
<property>
  <name>fs.defaultFS</name>
  <value>hdfs://$namenode</value>
</property>
EOF
	sed -i '/<configuration>/r tmpfile' etc/hadoop/core-site.xml || die
	# hdfs-site.xml
	cat >tmpfile<<EOF
<property>
  <name>dfs.namenode.name.dir</name>
  <value>file:/var/lib/hdfs/name</value>
</property>
<property>
  <name>dfs.datanode.data.dir</name>
  <value>file:/var/lib/hdfs/data</value>
</property>
<property>
  <name>dfs.namenode.secondary.http-address</name>
  <value>hdfs://${secondary}:50090</value>
</property>
<property>
  <name>dfs.replication</name>
  <value>$replication</value>
</property>
<property>
  <name>dfs.permissions.superusergroup</name>
  <value>hadoop</value>
</property>
EOF
	if [ $sandbox -ne 0 ] ; then cat >>tmpfile<<EOF
<property>
  <name>dfs.blocksize</name>
  <value>10M</value>
</property>
EOF
	fi
	sed -i '/<configuration>/r tmpfile' etc/hadoop/hdfs-site.xml ||die

	# yarn-site.xml
	cat >tmpfile<<EOF
<property>
  <name>yarn.nodemanager.aux-services</name>
  <value>mapreduce_shuffle</value>
</property>
<property>
  <name>yarn.resourcemanager.hostname</name>
  <value>$resmgr</value>
</property>
EOF
	if [ $sandbox -ne 0 ] ; then cat >>tmpfile<<EOF
<property>
  <name>yarn.nodemanager.resource.memory-mb</name>
  <value>384</value>
</property>
<property>
  <name>yarn.nodemanager.resource.cpu-vcores</name>
  <value>1</value>
</property>
<property>
  <name>yarn.scheduler.minimum-allocation-mb</name>
  <value>192</value>
</property>
<property>
  <name>yarn.scheduler.maximum-allocation-mb</name>
  <value>192</value>
</property>
<property>
  <name>yarn.nodemanager.vmem-check-enabled</name>
  <value>false</value>
</property>
EOF
	fi
	sed -i '/<configuration>/r tmpfile' etc/hadoop/yarn-site.xml || die

	# mapred-site.xml
	[ -f etc/hadoop/mapred-site.xml ] \
		|| cp etc/hadoop/mapred-site.xml.template etc/hadoop/mapred-site.xml
	cat >tmpfile<<EOF
<property>
  <name>mapreduce.framework.name</name>
  <value>yarn</value>
</property>
<property>
  <name>mapreduce.jobhistory.address</name>
  <value>$histsrv:10020</value>
</property>
EOF
	if [ $sandbox -ne 0 ] ; then cat >>tmpfile<<EOF
<property>
  <name>yarn.app.mapreduce.am.resource.mb</name>
  <value>192</value>
</property>
<property>
  <name>mapreduce.map.memory.mb</name>
  <value>192</value>
</property>
<property>
  <name>mapreduce.reduce.memory.mb</name>
  <value>192</value>
</property>
EOF
	fi
	sed -i '/<configuration>/r tmpfile' etc/hadoop/mapred-site.xml || die

	# make useful dirs
	diropts -m770 -o root -g hadoop
	dodir /var/log/hadoop
	dodir /var/lib/hdfs

	# install dir
	dodir "${INSTALL_DIR}"
	rm -f sbin/*.cmd etc/hadoop/*.cmd
	fperms g+w etc/hadoop/*
	mv "${S}"/* "${D}${INSTALL_DIR}"
	fowners -Rf root:hadoop "${INSTALL_DIR}"

	# env file
	cat > 99hadoop <<EOF
HADOOP_HOME="${INSTALL_DIR}"
HADOOP_YARN_HOME="${INSTALL_DIR}"
HADOOP_MAPRED_HOME="${INSTALL_DIR}"
PATH="${INSTALL_DIR}/bin"
CONFIG_PROTECT="${INSTALL_DIR}/etc/hadoop"
EOF
	doenvd 99hadoop

	# conf symlink
	dosym ${INSTALL_DIR}/etc/hadoop /etc/hadoop

	# init scripts
	newinitd "${FILESDIR}"/hadoop.init hadoop.init
	for i in "namenode" "datanode" "secondarynamenode" "resourcemanager" "nodemanager" "historyserver"
		do if [ `egrep -c "^[0-9].*#.*namenode" /etc/hosts` -eq 0 ] || [ `egrep -c "^[0-9].*${hostname}.*#.* ${i}" /etc/hosts` -eq 1 ] ; then
	   dosym  /etc/init.d/hadoop.init /etc/init.d/hadoop-"${i}"
	   fi
	done
	# opt synlink
	dosym "${INSTALL_DIR}" "/opt/${MY_PN}"
}

```


