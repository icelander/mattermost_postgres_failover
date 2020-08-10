#!/bin/bash
printf '=%.0s' {1..80}
echo 
echo 'PROVISIONING WITH THESE ARGUMENTS:'
echo $@
printf '=%.0s' {1..80}

echo "Updating apt Repositories"
apt-get -qq update > /dev/null 2>&1

cat /vagrant/hosts_file >> /etc/hosts

if [ "$1" != "" ]; then
    mattermost_version="$1"
else
	echo "Mattermost version is required"
    exit 1
fi

if [ "$2" != "" ]; then
    mattermost_password="$2"
else
	echo "Mattermost PostgreSQL password is required"
    exit 1
fi

echo "Installing PostgreSQL, GlusterFS, and jq"
apt-get install -y -q postgresql glusterfs-server postgresql-contrib jq


# Create Gluster Server Directory
mkdir -p /glusterfs/mmst_data

# Start Gluster
systemctl enable glusterd
service glusterd start

cp /etc/postgresql/10/main/pg_hba.conf /etc/postgresql/10/main/pg_hba.orig.conf
cp /vagrant/pg_hba.conf /etc/postgresql/10/main/pg_hba.conf

cp /etc/postgresql/10/main/postgresql.conf /etc/postgresql/10/main/postgresql.orig.conf
cp /vagrant/postgresql.conf /etc/postgresql/10/main/postgresql.conf

systemctl restart postgresql

echo "Setting up database"
cat /vagrant/db_setup.sql | sed "s/MATTERMOST_PASSWORD/$mattermost_password/g" > /tmp/db_setup.sql
su postgres -c "psql -f /tmp/db_setup.sql"
rm /tmp/db_setup.sql

rm -rf /opt/mattermost

echo /vagrant/mattermost_archives/mattermost-$mattermost_version-linux-amd64.tar.gz

if [[ ! -f /vagrant/mattermost_archives/mattermost-$mattermost_version-linux-amd64.tar.gz ]]; then
	echo "Downloading Mattermost"
	wget -q -P /vagrant/mattermost_archives/ https://releases.mattermost.com/$mattermost_version/mattermost-$mattermost_version-linux-amd64.tar.gz
fi

cp /vagrant/mattermost_archives/mattermost-$mattermost_version-linux-amd64.tar.gz ./	

echo "Unzipping Mattermost"
tar -xzf ./mattermost*.gz
mv mattermost /opt
mkdir /opt/mattermost/data

echo "Configuring Mattermost"

mv /opt/mattermost/config/config.json /opt/mattermost/config/config.orig.json
cat /vagrant/config.json | sed "s/MATTERMOST_PASSWORD/$mattermost_password/g" > /tmp/config.json
jq -s '.[0] * .[1]' /opt/mattermost/config/config.orig.json /tmp/config.json > /opt/mattermost/config/config.json
rm /tmp/config.json

mkdir /opt/mattermost/plugins
mkdir /opt/mattermost/client/plugins

echo "Creating Mattermost User"
useradd --system --user-group mattermost

echo "Adding Mattermost Service"
cp /vagrant/mattermost.service /lib/systemd/system/mattermost.service
systemctl daemon-reload

cd /opt/mattermost
echo "Installed Mattermost Version"

echo "Verifying /opt/mattermost permissions"
chown -R mattermost:mattermost /opt/mattermost
chmod -R g+w /opt/mattermost