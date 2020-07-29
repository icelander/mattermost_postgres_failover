#!/bin/bash

mkdir -p /mnt/glusterfs

echo 'localhost:/glusterfs /mnt/glusterfs glusterfs defaults,_netdev,backupvolfile-server=localhost 0 0' >> /etc/fstab

mount.glusterfs localhost:mmst_data /mnt/glusterfs

chown -R mattermost:mattermost /mnt/glusterfs/mmst_data

service mattermost start