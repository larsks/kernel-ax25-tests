#!/bin/sh

set -e

git clone https://github.com/ve7fet/linuxax25
cd /build/linuxax25
git config --global user.email root
git config --global user.name root
git am /build/alpine.patch

cd /build/linuxax25/libax25
./autogen.sh
./configure --prefix=/usr --sysconfdir=/etc
make
make install

mkdir -p /opt/ax25/bin /opt/ax25/sbin
cd /build/linuxax25/ax25tools
./autogen.sh
./configure --prefix=/usr --sysconfdir=/etc --bindir=/opt/ax25/bin --sbindir=/opt/ax25/sbin
sed -i '/^SUBDIRS =/ s/SUBDIRS = .*/SUBDIRS = ax25 kiss user_call man doc etc/' Makefile
make
make install

cd /build/linuxax25/ax25apps
./autogen.sh
./configure --prefix=/usr --sysconfdir=/etc --bindir=/opt/ax25/bin --sbindir=/opt/ax25/sbin
make
make install

ls -l /opt/ax25/*bin/
