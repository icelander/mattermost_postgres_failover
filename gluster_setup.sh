#!/bin/bash

apt-get install -y -q glusterfs-server

systemctl enable glusterd
service glusterd start

# Create Gluster Server Directory
mkdir -p /glusterfs/mmst_data

gluster peer probe app0
gluster peer probe app1

gluster volume create mmst_data replica 3 transport tcp \
	gateway:/glusterfs/mmst_data \
	app0:/glusterfs/mmst_data \
	app1:/glusterfs/mmst_data \
	force

gluster volume start mmst_data

mkdir -p /mnt/glusterfs

echo 'localhost:/glusterfs /mnt/glusterfs glusterfs defaults,_netdev,backupvolfile-server=localhost 0 0' >> /etc/fstab

mount.glusterfs localhost:mmst_data /mnt/glusterfs

mkdir -p /mnt/glusterfs/mmst_data/{data,plugins,client_plugins}