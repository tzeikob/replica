#!/bin/bash
set -eo pipefail
shopt -s nullglob

# Skip if we aren't running mongo related binaries
if [[ "$1" == mongo* ]]; then
  echo "Entrypoint script for MongoDB Server ${MONGO_VERSION} started"

  # Change data directory with permissions for mongodb user on running as root
  if [ "$(id -u)" = "0" ]; then
    echo "Switching to mongodb user"

    # Update data and config folder ownership
    find $MONGO_DATA_HOME \! -user mongodb -exec chown mongodb '{}' +
    find $MONGO_CONFIG_HOME \! -user mongodb -exec chown mongodb '{}' +

    # Make sure we can write to stdout and stderr as mongodb
    chown --dereference mongodb "/proc/$$/fd/1" "/proc/$$/fd/2" || :

    exec gosu mongodb "$BASH_SOURCE" "$@" --config $MONGO_CONFIG_HOME/mongod.conf
  fi

  # Enable replication mode
  if [ "$MONGO_REPLICA_SET" ]; then
    echo "MongoDB is running on replication mode with name $MONGO_REPLICA_SET"

    # Uncomment replication line to enable replica set to the given name
    sed -i "/#replication/c\replication:\n  replSetName: $MONGO_REPLICA_SET" $MONGO_CONFIG_HOME/mongod.conf
  fi

  # Use numactl to start your mongod, config servers and mongos
  numa='numactl --interleave=all'
  if $numa true &> /dev/null; then
    set -- $numa "$@"
  fi
fi

exec "$@"