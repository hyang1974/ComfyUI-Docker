#!/bin/bash

echo "########################################"
echo "Downloading new models......."
echo "########################################"

set -euxo pipefail


cd /home/runner/ComfyUI
aria2c --input-file=/home/runner/update.txt \
    --allow-overwrite=false --auto-file-renaming=false --continue=true \
    --max-connection-per-server=5

# Finish
echo "New models download completed."
mv -f /home/runner/update.txt /home/runner/.update.txt.completed
