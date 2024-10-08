#!/bin/bash
set -euo pipefail

# Install CUDA Toolkit 12.4
echo "Installing CUDA Toolkit 12.4..."
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb -O /tmp/cuda-keyring.deb
sudo dpkg -i /tmp/cuda-keyring.deb
sudo apt-get update
sudo apt-get install -y cuda-toolkit-12-4

echo "CUDA Toolkit 12.4 installation completed."
