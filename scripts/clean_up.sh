#!/bin/bash
set -euo pipefail

echo "Cleaning up temporary files..."
sudo rm -rf /var/tmp/*
sudo rm -rf /tmp/*
sudo apt-get clean

echo "Cleanup completed."
