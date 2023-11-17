#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

cp -p /container/.wine/drive_c/nolf/NetHost.txt /config/nolf/NetHost.txt
