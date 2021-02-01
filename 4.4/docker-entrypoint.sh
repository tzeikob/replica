#!/bin/bash
set -eo pipefail
shopt -s nullglob

# Append any given mongod command line configuration argument
if [ "${1:0:1}" = '-' ]; then
  set -- mongod "$@"
fi

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

    # Use the configuration file if executing mongo daemon
    if [[ "$1" == mongod ]]; then
      # Config arguments will override any corresponding setting in the config file
      exec gosu mongodb "$BASH_SOURCE" "$@" --config $MONGO_CONFIG_HOME/mongod.conf
    else
      exec gosu mongodb "$BASH_SOURCE" "$@"
    fi
  fi

  # Use numactl to start your mongod, config servers and mongos
  numa='numactl --interleave=all'
  if $numa true &> /dev/null; then
    set -- $numa "$@"
  fi
fi

exec "$@"