#!/bin/bash
set -eo pipefail
shopt -s nullglob

# Skip if we aren't running mongo related binaries
if [[ "$1" == mongo* ]]; then
  echo "Entrypoint script for MongoDB Server ${MONGO_VERSION} started"

  # Declare data and config directory paths
  declare -g DATADIR CONFIGDIR
  DATADIR="/data/db"
  CONFIGDIR="/etc/mongo"

  # Change data directory with permissions for mongodb user on running as root
  if [ "$(id -u)" = "0" ]; then
    echo "Switching to mongodb user"

    # Update data and config folder ownership
    find $DATADIR \! -user mongodb -exec chown mongodb '{}' +
    find $CONFIGDIR \! -user mongodb -exec chown mongodb '{}' +

    # Make sure we can write to stdout and stderr as mongodb
    chown --dereference mongodb "/proc/$$/fd/1" "/proc/$$/fd/2" || :

    exec gosu mongodb "$BASH_SOURCE" "$@"
  fi

  # Enable replication mode
  if [ "$REPLICA_SET_NAME" ]; then
    echo "Container is running in replication mode with name $REPLICA_SET_NAME"

    # Uncomment replication line to enable replica set to the given name
    sed -i "/#replication/c\replication:\n  replSetName: $REPLICA_SET_NAME" $CONFIGDIR/mongod.conf
  fi

  # Use numactl to start your mongod, config servers and mongos
  numa='numactl --interleave=all'
  if $numa true &> /dev/null; then
    set -- $numa "$@"
  fi
fi

exec "$@"