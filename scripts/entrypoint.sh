#!/bin/bash

set -e

# Install ComfyUI
cd /home/runner
if [ ! -f "/home/runner/.download-complete" ] ; then
    chmod +x /home/scripts/download.sh
    bash /home/scripts/download.sh
fi ;

# Download new models if update.txt exists
cd /home/runner
if [ -f "/home/runner/update.txt" ] ; then
    chmod +x /home/scripts/update.sh
    bash /home/scripts/update.sh
else
    echo "No update scrpit found. Skipping."
fi ;

# Run user's pre-start script
cd /home/runner
if [ -f "/home/runner/scripts/pre-start.sh" ] && [ ! -f "/home/runner/.pre-start-complete" ] ; then
    echo "########################################"
    echo "Running pre-start script..."
    echo "########################################"

    chmod +x /home/runner/scripts/pre-start.sh
    bash /home/runner/scripts/pre-start.sh
else
    echo "No pre-start script found. Skipping."
fi ;


echo "########################################"
echo "Starting ComfyUI..."
echo "########################################"

export PATH="${PATH}:/home/runner/.local/bin"

cd /home/runner

python3 ./ComfyUI/main.py --listen --port 8188 ${CLI_ARGS}
