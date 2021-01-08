#!/bin/bash
set -eo pipefail
shopt -s nullglob

echo "Entering the entry point script"

exec "$@"