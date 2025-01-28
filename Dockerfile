FROM  rockylinux:8


# Install required packages
RUN set -ex \
	&& dnf -y clean all \
	&& dnf -y install 'dnf-command(config-manager)' \
	&& dnf -y config-manager --set-enabled powertools \
	&& dnf -y install epel-release \
	&& rpm --import https://package.perforce.com/perforce.pubkey \
	&& { \
	echo [perforce]; \
	echo name=Perforce; \
	echo baseurl=http://package.perforce.com/yum/rhel/8/x86_64; \
	echo enabled=1; \
	echo gpgcheck=1; \
	} > /etc/yum.repos.d/perforce.repo \
	&& dnf -y update \
	&& dnf -y install dnf-utils epel-release rpmdevtools helix-cli \
	&& rpmdev-setuptree \
	&& dnf -y install \
	gcc gcc-c++ make perl libtool python2 python3 git autoconf automake m4 rpm-build gdb \
	libX11-devel libXt-devel libXext-devel libXft-devel elfutils-libelf-devel glibc-static ncurses-devel \
	openssl-devel sudo which tar wget rsync curl openssh-server openssh-clients \
	net-tools bind-utils cpan tzdata vim iputils glibc-common valgrind-devel \
	time csh file man-db lsof perl-Env perl-Switch python3-pip expect postfix libffi libffi-devel pciutils-devel \
	perl-App-cpanminus libcap rsyslog llvm bc gzip initscripts pam-devel glibc-langpack-en \
	numactl-devel libxml2-devel jemalloc-devel libtirpc-devel \
	&& wget -O /usr/local/bin/tini https://github.com/krallin/tini/releases/download/v0.18.0/tini-static-amd64 \
	&& chmod +x /usr/local/bin/tini \
	&& dnf -y clean all \
	&& rm -rf /var/cache/* /tmp/* /var/tmp/*

ENV LANGUAGE=en_US.utf8 LANG=en_US.utf8

# Install openssl
Run wget --no-check-certificate https://www.openssl.org/source/openssl-1.1.1g.tar.gz \
    && tar -zxf openssl-1.1.1g.tar.gz && cd openssl-1.1.1g \
    && ./config --prefix=/opt/tools/openssl --openssldir=/opt/tools/openssl no-ssl2 \
    && make \
    && make install

# Install relevant cmake version
RUN yum remove cmake -y \
	&& wget https://cmake.org/files/v3.19/cmake-3.19.2-Linux-x86_64.sh \
	&& mkdir -p /opt/tools \
	&& bash cmake*.sh --prefix=/opt/tools --skip-license \
	&& rm -rf cmake*.sh

# Install required perl modules
RUN set -ex \
	&& mkdir -p /usr/local/perl58/bin \
	&& ln -s /usr/bin/perl /usr/local/perl58/bin/perl \
	&& curl -Lk https://git.io/cpanm | perl - --sudo -n App::cpanminus \
	&& cpanm -n --no-lwp \
	IO::Pty IPC::Run IPC::Cmd Class::Accessor Module::Build Pod::Usage \
	Getopt::Long DateTime Date::Parse Proc::ProcessTable Test::More \
	Unix::Process Time::HiRes File::FcntlLock File::Remote \
	&& rm -rf ~/.cache ~/.cpanm /tmp/*

# Install pip, requests and sh python modules
RUN set -ex \
	&& python3 -m pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org certifi requests sh \
	&& pip3 install wheel \
	&& pip3 install pyinstaller \
	&& rm -rf ~/.cache /tmp/*

# Install and start munge service
RUN set -ex \
	&& dnf -y update \
	&& dnf -y install munge \
	&& dnf -y install munge-devel \
	&& create-munge-key \
	&& sudo -u munge /usr/sbin/munged --syslog
