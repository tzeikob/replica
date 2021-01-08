#!/bin/bash
set -eo pipefail
shopt -s nullglob

# Skip if we aren't running mongo related binaries
if [[ "$1" == mongo* ]]; then
  echo "Entrypoint script for MongoDB Server ${MONGO_VERSION} started"

  # Declare data directory path
  declare -g DATADIR
  DATADIR="/data/db"

  # Change data directory with permissions for mongodb user on running as root
  if [ "$(id -u)" = "0" ]; then
    echo "Switching to mongodb user"

    # Todo: Maybe catch this if running "mongod" only
    find $DATADIR \! -user mongodb -exec chown mongodb '{}' +

    # Make sure we can write to stdout and stderr as mongodb
    chown --dereference mongodb "/proc/$$/fd/1" "/proc/$$/fd/2" || :

    exec gosu mongodb "$BASH_SOURCE" "$@"
  fi

  # Use numactl to start your mongod, config servers and mongos
  numa='numactl --interleave=all'
  if $numa true &> /dev/null; then
    set -- $numa "$@"
  fi
fi

exec "$@"