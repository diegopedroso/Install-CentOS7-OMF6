#! /bin/bash

yum -y update
yum -y install curl
yum -y install dnsmasq
yum -y install zlib-devel
yum -y install wget
yum -y install xmlsec1-openssl
yum -y install syslinux
yum -y install python
yum -y install ntp
yum -y install xmlsec1-devel
yum -y install libyam-devel
yum -y install libyaml-devel
yum -y install libreadline-devel
yum -y install readline-devel
yum -y install libsqlite3-devel
yum -y install epel-release
yum -y install sqlite-devel
yum -y install libsqlite3x-devel
yum -y install virt-install
yum -y groupinstall 'Development Tools'
yum -y install libssl-devel
yum -y install openssl-devel
yum -y install gcc-c++ 
