## Quick reference
 * Maintained by: [tzeikob](https://github.com/tzeikob/replica)
 * Where to get help: [Docker Community Forums](https://forums.docker.com/) [Docker Community Slack](https://dockr.ly/slack), or [Stack Overflow](https://stackoverflow.com/search?tab=newest&q=docker)

## Supported tags and respective `Dockerfile` links
 * [4.4, latest](https://github.com/tzeikob/replica/blob/main/4.4/Dockerfile)

## Quick reference (cont.)
 * Where to file issues: [bug tracker](https://github.com/tzeikob/replica/issues)
 * Supported architectures: amd64

## What is the Replica?

Replica is just a docker image running a MongoDB Server ready for you to setup replica set clusters, for trivial and development purposes only. It's purpose is to speed your workflow up and save you from the hassle of installing and setting it up from scratch. Each container is capable of running as a `mongod` daemon in `standalone` mode, in `config` mode or in `router` mode in the case of a sharded cluster.

## How to use this image

### Start a standalone server

Starting a standalone server is simple:

```
mkdir -p any-name
cd any-name

docker run -d --name any-name \
  -p 27017:27017 \
  -v $(pwd)/data:/data/db \
  tzeikob/replica:tag
```

where `any-name` is the name you want to assign to the container and tag is the tag specifying the version of the MongoDB server. After that the server should be ready for connections at `mongodb://127.0.0.1:27017/db-name`.

>Note, the container will be attached to the default `bridge` docker network.

### Start a single member replica set

You can create a container running as a single member replica set like so:

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
  members: [{ _id: 0, host: "localhost:27017" }]
});
```

after that the single member replica set will be ready for connections at `mongodb://localhost:27017/db-name?replicaSet=rs0`.

>Note, the container will be attached to the `host` network, not the default `bridge` network.

### Start a three member replica set

In order to create a three member replica set, you have to start three separate containers running as a standalone server and initiate the replication like so:

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
    { _id: 0, host: "localhost:27017" },
    { _id: 1, host: "localhost:27018" },
    { _id: 2, host: "localhost:27019" }
  ]
});
```

at this point the replica set will be ready for connections at `mongodb://localhost:27017,localhost:27018,localhost:27019/db-name?replicaSet=rs0`.

>Note, all the containers will be attached to the `host` network, not the default `bridge` network.

#### Using custom bridge network

So far we've used the `host` network to attach each container of the replica set, that's why we didn't use the port mapping flag `-p 2701x:2701x`. Another way is to use instead a custom `bridge` docker network, first create a new custom bridge network,

```
docker network create --driver bridge my-network
```

after that you should start each container with `--network my-network` network instead of the `--network host` and give a different `port` to each replica member to avoid conflicts. Make sure for each container that both the exposed and inner ports are matching via `-p 2701x:2701x` and the `mongod` daemon is set to start at the same port `--port 2701x`. Having all the containers up and running, connect to the first one and initiate the replica set with the following configuration.

```
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

The final step is to add the following rules into the `/etc/hosts` file in your host disk in order to resolve each container's host,

```
127.0.0.1 n1
127.0.0.1 n2
127.0.0.1 n3
```

this way your replicat set will be ready for connections at `mongodb://n1:27017,n2:27018,n3:27019/db-name?repliaSet=rs0`.

### Mount database files to the host

In order to mount the container's database files (`/data/db`) into your host, you only have to use the volume flag like so:

```
docker run -d --name any-name \
  -p 27017:27017 \
  -v $(pwd)/data:/data/db \
  tzeikob/replica:tag
```

this way you can remove the container and start it again anytime without losing the old data, you only have to mount the host folder `$(pwd)/data` as a volume back to the new container.

### Mount other folders and files to the container

In order to mount host's folders and files to be available into the container you have to create them beforehand into the host disk and use the volume flag and instruct the docker to use read and write (`rw`) permissions like so:

```
mkdir -p any-name
cd any-name

mkdir -p scripts

docker run -d --name any-name \
  -p 27017:27017 \
  -v $(pwd)/scripts:/home/scripts/:rw \
  tzeikob/replica:tag
```

### Customize configuration

#### Enable configuration via command line arguments

You can set any configuration settings via command line arguments like so:

```
mkdir -p any-name
cd any-name

docker run -d --name any-name \
  -p 27111:27111 \
  -v $(pwd)/data:/data/db \
  tzeikob/replica:tag \
  --port 27111
```

in this case we override the default port `27017` by a given command line argument, in order to start the server at the port `27111`. This way you can set any configuration option is listed in the mongodb's documentation.

#### Customize configuration via a custom configuration file

You can also customize the configuration of the server by providing your configuration file `mongod.conf` at the creation of the container like so:

```
run -d --name any-name \
  -p 27017:27017 \
  -v $(pwd)/data:/data/db \
  -v $(pwd)/config/mongod.conf:/etc/mongo/mongod.conf \
  tzeikob/replica:tag
```

> Note, any given configuration passed as command line argument will override the corresponding setting in the configuration file, in case both methods have been used.

the configuration file `config/mongod.conf` will replace the existing default `/etc/mongo/mongod.conf` file in the container's host. You can find below a base configuration file to start with mongo daemon configuration,

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