# Blue/Green Failover with PostgreSQL and rubyrep

## Problem

You want to have a Mattermost server with its own PostgreSQL server in a hot-standby configuration

## Solution

*Note:* These instructions are for Ubuntu 18.04

### 1. Set up two Mattermost servers w/ a PostgreSQL server

[Instructions are available here](https://docs.mattermost.com/install/install-ubuntu-1804.html). Note that while you set up two servers, do not configure them as a cluster. Also, run these PostgreSQL queries so that the Bucardo user can connect to the database as well as the Mattermost user.

### 2. Set up a third server as the proxy using HAProxy

1. `sudo apt-get install haproxy`
2. Configure HAProxy as shown in `haproxy.cfg`
3. Restart haproxy with `sudo service haproxy restart`

### 4. Set up Bucardo

On the same server as the HAProxy server, install PostgreSQL like you did on the Mattermost application servers. Then, create the directories necessary for bucardo:

```bash
mkdir -p /var/run/bucardo
mkdir -p /var/log/bucardo
touch /var/log/bucardo/log.bucardo
```

Once that's done, install the Perl dependencies for Bucardo:

```bash
apt-get -y install libdbix-safe-perl libdbd-pg-perl postgresql-plperl
```

Now you're ready to download the latest version of Bucardo and install it:

```bash
wget -q https://github.com/bucardo/bucardo/archive/5.5.0.tar.gz

tar -xzf 5.5.0.tar.gz

cd bucardo-5.5.0

perl Makefile.PL
make
make install
```

Now that you have the Bucardo binary install run this command to install the necessary tables into the Bucardo database:

```bash
bucardo install
```

For this example the defaults are fine. Now you're ready to set up replication. First, add the green and blue PostgreSQL servers:

```bash
bucardo add db green dbname=mattermost host=192.168.33.102 user=bucardo pass=bucardo port=5432
bucardo add db blue dbname=mattermost host=192.168.33.103 user=bucardo pass=bucardo port=5432
```

Then create the sync. To do a two-way or multi-master sync specify both databases as the source:

```bash
bucardo add sync mattermost dbs=green:source,blue:source tables=all
```

Finally, start the Bucardo sync job:

```bash
bucardo start
```

Your databases will now be kept in sync by Bucardo, and if the main Mattermost server it will fail over automatically to the standby server. As changes are made to the standby server's database they're synced within a couple seconds to the main server's database. Once the main server comes back up it will have all the posts made during its downtime.

## Discussion

### What is bucardo?

Bucardo is a collection of Perl scripts that allow you to sync databases in a master/slave or master/master configuration. Also, while the source must be a PostgreSQL database, the target can be PostgreSQL, MySQL, Redis, Oracle, SQLite, or MongoDB. 

While the terms used in bucardo can be a little strange - goats and kids and herds - setting up syncing is relatively easy. While this will be slower than PostgreSQL's native streaming replication, it's the only solution I've found to 

### Production Considerations

One thing to note is that if one of the replicated databases becomes disconnected it will stall the Bucardo syncs. [There is a suggested workaround on the Bucardo Github page](https://github.com/bucardo/bucardo/issues/88#issuecomment-216291651), but note that it may take a second or two for the sync to catch up. To manually start the sync, use `bucardo kick mattermost`

### What about syncing plugins?

Plugins will have to be synced from the green server to the blue server after they're installed, using these commands (run from the blue server):

```bash
rsync green-server:/opt/mattermost/plugins/ /opt/mattermost/plugins/
rsync green-server:/opt/mattermost/client/plugins/ /opt/mattermost/client/plugins/
chown -R mattermost:mattermost /opt/mattermost/
```

To run this automatically you'll have to create an SSH account on the Mattermost servers.