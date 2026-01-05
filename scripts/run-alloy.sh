#!/usr/bin/bash

# Run the Alloy application with the specified configuration
sudo cp -f "$(cd "$(dirname "$0")" && pwd)/config.alloy" /etc/alloy/config.alloy
sudo systemctl enable --now alloy