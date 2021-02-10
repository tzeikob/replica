## Quick reference
 * Maintained by: [tzeikob](https://github.com/tzeikob/replica)
 * Where to get help: [Docker Community Forums](https://forums.docker.com/) [Docker Community Slack](https://dockr.ly/slack), or [Stack Overflow](https://stackoverflow.com/search?tab=newest&q=docker)

## Supported tags and respective `Dockerfile` links
 * [4.4, latest](https://github.com/tzeikob/replica/blob/main/4.4/Dockerfile)

## Quick reference (cont.)
 * Where to file issues: [bug tracker](https://github.com/tzeikob/replica/issues)
 * Supported architectures: amd64

## What is the Replica?

Replica is just a docker image running a MongoDB Server ready for you to setup standalone servers and replica set clusters, for trivial and development purposes only. It's purpose is to speed your workflow up and save you from the hassle to install and setup everything from scratch. The container is capable of running as a `mongod` daemon in `standalone` mode, in `config` mode or in `router` (mongos) mode in the case of a sharded cluster.

## How to use this image

### Start a standalone server

Starting a standalone server is simple:

```
docker run -d --name any-name \
  -p 27017:27017 \
  -v $(pwd)/data:/data/db \
  tzeikob/replica \
  --port 27017
```

where `any-name` is the name you want to assign to the container. After that the server should be ready for connections at `mongodb://localhost:27017/db-name`.

>Note, the container will be attached to the default `bridge` docker network.

### Start a single member replica set

You can create a container running as a single member replica set like so,

```
docker run -d --name any-name \
  -p 27017:27017 \
  -v $(pwd)/data:/data/db \
  tzeikob/replica \
  --replSet rs0 \
  --port 27017
```

> Note, the `host` port should match the `exposed` port the mongod is running at, otherwise you will not be able to resolve connections from the host to the replica set.

connect to the container and open the mongo shell to initiate the replica set with the configuration below,

```
rs.initiate({
  _id: "rs0",
  version: 1,
  members: [{ _id: 0, host: "localhost:27017" }]
});
```

after that replica set will be ready for connections at `mongodb://localhost:27017/db-name?replicaSet=rs0`.

>Note, the container will be attached to the default `bridge` docker network.

### Start a three member replica set

In order to create a replica set of three members, you have to start three separate containers attached to the same docker network. So first create a custom `bridge` docker network like so:

```
docker network create --driver bridge my-network
```

then create three containers (n1, n2, n3) attached to the `my-network` network and with replication name set to `rs0`,

```
docker run -d --name n1 \
  --network my-network \
  -p 27017:27017 \
  -v $(pwd)/data/n1:/data/db \
  tzeikob/replica \
  --replSet rs0 \
  --port 27017

docker run -d --name n2 \
  --network my-network \
  -p 27018:27018 \
  -v $(pwd)/data/n2:/data/db \
  tzeikob/replica \
  --replSet rs0 \
  --port 27018

docker run -d --name n3 \
  --network my-network \
  -p 27019:27019 \
  -v $(pwd)/data/n3:/data/db \
  tzeikob/replica \
  --replSet rs0 \
  --port 27019
```

> Note, you can use this docker-compose [template](https://github.com/tzeikob/replica/blob/main/templates/replica-set.yml) instead of manually creating the `network` and the `containers`. Download it and just run the following command:
> 
> ```
> docker-compose -p project-name -f ./replica-set.yml up -d
> ```
> 
> where `project-name` can be any name related to your project.

after that you will have three containers running in replication mode ready for configuration, so connect to the first container (let's say n1) open the mongo shell and initiate the replica set like so:

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

in order to be able to get connection to the replica set, add the following three mapping dns rules to the `/etc/hosts` file, one for each of the corresponding containers,

```
127.0.0.1 n1
127.0.0.1 n2
127.0.0.1 n3
```

at this point the replica set should be ready for connections at `mongodb://n1:27017,n2:27018,n3:27019/db-name?replicaSet=rs0`.

>Note, all the containers will be attached to the custom `bridge` docker network named `my-network`.

### Customize configuration

#### Enable configuration via command line arguments

You can use any configuration settings via command line arguments like so:

```
docker run -d --name any-name \
  -p 27111:27111 \
  -v $(pwd)/data:/data/db \
  tzeikob/replica \
  --port 27111
```

in this case we override the default port `27017` by a given command line argument, in order to start the server at the port `27111`. This way you can set any configuration option from those listed in the mongodb's [documentation](https://docs.mongodb.com/manual/reference/configuration-file-settings-command-line-options-mapping/).

#### Customize configuration via a custom configuration file

You can also customize the configuration of the server by providing your configuration file, let's say you have a configuration file at `$(pwd)/config/mongod.conf`, create a container like so:

```
run -d --name any-name \
  -p 27017:27017 \
  -v $(pwd)/data:/data/db \
  -v $(pwd)/config/mongod.conf:/etc/mongo/mongod.conf \
  tzeikob/replica \
  --config /etc/mongo/mongod.conf
```

> Note, any given configuration passed as command line argument will override the corresponding setting in the configuration file, in case both methods have been used.

You can find a template [here](https://github.com/tzeikob/replica/blob/main/templates/mongod.conf) as a base configuration file to start with.

### Mount database files to the host

In order to mount the container's database files (`/data/db`) into your host, you only have to use the volume flag like so:

```
docker run -d --name any-name \
  -p 27017:27017 \
  -v $(pwd)/data:/data/db \
  tzeikob/replica \
  --port 27017
```

this way you can remove the container and start it again anytime without losing the old data, you only have to mount the host folder `$(pwd)/data` as a volume back to the container's db folder `/data/db`.

### Mount other folders and files to the container

In order to mount host's folders and files to be available into the container you have to create them beforehand into the host disk and use the volume flag and instruct the docker to use read and write (`rw`) permissions like so:

```
docker run -d --name any-name \
  -p 27017:27017 \
  -v $(pwd)/scripts:/home/scripts/:rw \
  tzeikob/replica \
  --port 27017
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