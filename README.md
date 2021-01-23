## Quick reference
 * Maintained by: [tzeikob](https://github.com/tzeikob/replica)
 * Where to get help: [Docker Community Forums](https://forums.docker.com/) [Docker Community Slack](https://dockr.ly/slack), or [Stack Overflow](https://stackoverflow.com/search?tab=newest&q=docker)

## Supported tags and respective `Dockerfile` links
 * [4.4, latest](https://github.com/tzeikob/replica/blob/main/4.4/Dockerfile)

## Quick reference (cont.)
 * Where to file issues: [bug tracker](https://github.com/tzeikob/replica/issues)
 * Supported architectures: amd64

## What is the Replica?

Replica is just a MongoDB Server docker image made for trivial and development purposes only, it's purpose is to speed your workflow up and save you from the hassle of installing and setting up a server at your own. Each container you create from this image will be a clean single node MongoDB server.

## How to use this image

### Start a single node server

Starting a single node server is simple:

```
mkdir -p any-name
cd any-name

docker run -d --name any-name \
  -p 27017:27017 \
  -v $(pwd)/data:/data/db \
  tzeikob/replica:tag
```

where `any-name` is the name you want to assign to the container and tag is the tag specifying the version of the MongoDB server. After that the MongoDB Server should be ready to accept connections at `mongodb://127.0.0.1:27017/db-name`.

>Note, the container will be attached to the default docker host network, which is the `bridge` network.

### Start a single member replica set

You can create a container running as a single node server in replication mode like so:

```
mkdir -p any-name
cd any-name

docker run -d --network host --name any-name \
  -v $(pwd)/data:/data/db \
  tzeikob/replica:tag \
  --replSet rs0 \
  --port 27017
```

then you should connect to the container and initiate the replica set with a given configuration:

```
docker exec -it any-name bash

mongo --port 27017

rs.initiate({
  _id: "rs0",
  version: 1,
  members: [{ _id: 0, host: "any-name:27017" }]
});
```

after that the single member replica set will be ready to accept connections at `mongodb://127.0.0.1:27017/db-name?replicaSet=rs0`.

>Note, that the container will be attached to the `host` network, not the default docker host network which is the `bridge` network.

### Start a replica set of three members

In order to create a three member replica set, you have to start three separate containers running as a single node server in replication mode like so:

```
mkdir -p any-name
cd any-name

docker run -d --network host --name n1 \
  -v $(pwd)/data/n1:/data/db \
  tzeikob/replica:tag \
  --replSet rs0 \
  --port 27017

docker run -d --network host --name n2 \
  -v $(pwd)/data/n2:/data/db \
  tzeikob/replica:tag \
  --replSet rs0 \
  --port 27018

docker run -d --network host --name n3 \
  -v $(pwd)/data/n3:/data/db \
  tzeikob/replica:tag \
  --replSet rs0 \
  --port 27019
```

after that you will have 3 different containers running in replication mode ready for configuration. Connect to the first one and initiate the replica set like so:


```
docker exec -it n1 bash

mongo --port 27017

rs.initiate({
  _id: "rs0",
  version: 1,
  members: [
    { _id: 0, host: "n1:27017" },
    { _id: 1, host: "n2:27018" },
    { _id: 2, host: "n3:27019" }
  ]
});
```

at this point the replica set `rs0` will be ready for connections at `mongodb://127.0.0.1:27017,127.0.0.1:27018,127.0.0.1:27019/db-name?replicaSet=rs0`.

>Note, that all the containers will be attached to the `host` network, not the default docker host network which is the `bridge` network.

### Mount database files to the host

In order to mount the container's database files (`/data/db`) into your host, you only have to use the volume flag like so:

```
docker run -d --name any-name \
  -p 27017:27017 \
  -v $(pwd)/data:/data/db \
  tzeikob/replica:tag
```

keep in mind that you can remove the docker container at anytime, as long as you keep the `/data` folder on your host disk the next time you run/create again a new container instance with the `/data/db` volume mounted to this `/data` folder, the same database files will be used for the MongoDB Server.

### Mount folders and files from the host to the container

In order to mount host's folders and files to be available into the container you have to create them beforehand into the host disk and use again the volume flag and instruct the docker to use read and write permissions (`rw`) like so:

```
mkdir -p scripts

docker run -d --name any-name \
  -p 27017:27017 \
  -v $(pwd)/data:/data/db \
  -v $(pwd)/scripts:/home/scripts/:rw \
  tzeikob/replica:tag
```

### Customize configuration with a custom configuration file

You can customize the configuration of the MongoDB server by providing your configuration file `mongod.conf` at the creation of the container like so:

```
run -d --name any-name \
  -p 27017:27017 \
  -v $(pwd)/data:/data/db \
  -v $(pwd)/config/mongod.conf:/etc/mongo/mongod.conf \
  tzeikob/replica:tag
```

the configuration file `config/mongod.conf` will replace the existing default `/etc/mongo/mongod.conf` file. You can find below, a base configuration file to start with mongo daemon configuration.

```
# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# Where and how to store data.
storage:
  dbPath: /data/db
  journal:
    enabled: true
#  engine:
#  mmapv1:
#  wiredTiger:

# where to write logging data.
# systemLog:
#   destination: file
#   logAppend: true
#   path: /var/log/mongodb/mongod.log

# network interfaces
net:
  port: 27017
  bindIp: 0.0.0.0

# how the process runs
processManagement:
  timeZoneInfo: /usr/share/zoneinfo

#security:

#operationProfiling:

#replication:

#sharding:

## Enterprise-Only Options:

#auditLog:

#snmp:
```

### Access the container's shell

The docker exec command allows you to run commands inside a Docker container. The following command line will give you a bash shell inside your MongoDB server container:

```
docker exec -it any-name bash
```

### View the container's log file

The log is available through Docker's container log, you can tail of the file by using the `follow` flag:

```
docker logs -f -n all any-name
```

### Create database dump files

A simple way to create database dumps is to use `docker exec` and run the tool from the same container, like so:

```
docker exec any-name sh -c 'exec mongodump -d db-name --archive' > path/to/db-name.archive
```

## License
View [license](https://github.com/mongodb/mongo/blob/6ea81c883e7297be99884185c908c7ece385caf8/README#L89-L95) information for the software contained in this image.

It is relevant to note the change from AGPL to SSPLv1 for all versions after October 16, 2018.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.