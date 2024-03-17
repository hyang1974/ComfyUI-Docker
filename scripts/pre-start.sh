#!/bin/bash

sudo chown -R runner: /usr/local/
echo "Pre start script execution completed."

touch "/home/runner/.pre-start-complete"
