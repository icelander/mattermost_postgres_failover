#!/bin/bash

echo "Installing PostgreSQL"
apt-get install -y -q postgresql postgresql-contrib jq

cp /etc/postgresql/10/main/pg_hba.conf /etc/postgresql/10/main/pg_hba.orig.conf
cp /vagrant/pg_hba.conf /etc/postgresql/10/main/pg_hba.conf

cp /etc/postgresql/10/main/postgresql.conf /etc/postgresql/10/main/postgresql.orig.conf
cp /vagrant/postgresql.conf /etc/postgresql/10/main/postgresql.conf

systemctl restart postgresql

echo "Setting up database"
cat /vagrant/db_setup.sql | sed "s/MATTERMOST_PASSWORD/really_secure_password/g" > /tmp/db_setup.sql
su postgres -c "psql -f /tmp/db_setup.sql"
rm /tmp/db_setup.sql

mkdir -p /var/run/bucardo
mkdir -p /var/log/bucardo
touch /var/log/bucardo/log.bucardo
apt-get -y install libdbix-safe-perl libdbd-pg-perl postgresql-plperl

wget -q https://github.com/bucardo/bucardo/archive/5.5.0.tar.gz

tar -xzf 5.5.0.tar.gz

cd bucardo-5.5.0

perl Makefile.PL
make
make install

bucardo install --batch

bucardo add db green dbname=mattermost host=192.168.33.102 user=bucardo pass=bucardo port=5432
bucardo add db blue dbname=mattermost host=192.168.33.103 user=bucardo pass=bucardo port=5432
bucardo add sync mattermost dbs=green:source,blue:source tables=all
bucardo start