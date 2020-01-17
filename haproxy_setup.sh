#!/bin/bash

echo "Updating Apt Repositories"
apt-get -q -q -y update

apt-get -y install haproxy
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.orig.cfg
cp /vagrant/haproxy.cfg /etc/haproxy/haproxy.cfg

service haproxy start