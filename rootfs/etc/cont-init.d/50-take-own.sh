#!/bin/sh
set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

cp -p /config/nolf/NetHost.txt /container/.wine/drive_c/nolf/NetHost.txt

take-ownership /container
