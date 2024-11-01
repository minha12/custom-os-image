#!/bin/bash

# Bash script to install Miniforge 3 on Ubuntu 24.04 and automatically activate the env by updating .bashrc

# Step 1: Define Miniforge installer URL for the current system
OS=$(uname)  # Should return 'Linux' for Ubuntu
ARCH=$(uname -m)  # Should return 'x86_64' for 64-bit machines, 'aarch64' for arm64

# The expected installer name is structured like this: Miniforge3-Linux-x86_64.sh or Miniforge3-Linux-aarch64.sh
INSTALLER_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-${OS}-${ARCH}.sh"
INSTALLER_FILE="Miniforge3-${OS}-${ARCH}.sh"
MINIFORGE_PATH="${HOME}/miniforge3"  # Directory where Miniforge will be installed

echo "Downloading Miniforge installer from $INSTALLER_URL..."

# Step 2: Download the Miniforge installer
curl -L -O "$INSTALLER_URL"

# Step 3: Check if the download was successful
if [ -f "$INSTALLER_FILE" ]; then
    echo "Miniforge installer downloaded successfully."
else
    echo "Download failed. Please check your network connection or URL."
    exit 1
fi

# Step 4: Run the Miniforge installer in non-interactive (batch) mode
echo "Installing Miniforge..."
bash "$INSTALLER_FILE" -b -p "$MINIFORGE_PATH"

# Step 5: Check if Conda is available after the installation
CONDA_PATH="$MINIFORGE_PATH/bin/conda"
if [ -f "$CONDA_PATH" ]; then
    echo "Miniforge installed successfully."
else
    echo "Conda not found. Installation may have failed."
    exit 1
fi

# Step 6: Add Miniforge initialization to .bashrc (if it's not already there)
BASHRC_FILE="${HOME}/.bashrc"
CONDA_INIT_MARKER="# >>> conda initialize >>>"
MAMBA_INIT_PATH="$MINIFORGE_PATH/etc/profile.d/mamba.sh"
CONDA_SETUP="
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup=\"\$('$MINIFORGE_PATH/bin/conda' 'shell.bash' 'hook' 2> /dev/null)\"
if [ \$? -eq 0 ]; then
    eval \"\$__conda_setup\"
else
    if [ -f \"$MINIFORGE_PATH/etc/profile.d/conda.sh\" ]; then
        . \"$MINIFORGE_PATH/etc/profile.d/conda.sh\"
    else
        export PATH=\"$MINIFORGE_PATH/bin:\$PATH\"
    fi
fi
unset __conda_setup

# Add support for Mamba if available
if [ -f \"$MAMBA_INIT_PATH\" ]; then
    . \"$MAMBA_INIT_PATH\"
fi
# <<< conda initialize <<<
"

# Check if the initialization block is already added to .bashrc
if ! grep -q "$CONDA_INIT_MARKER" "$BASHRC_FILE"; then
    echo "Adding conda initialization to $BASHRC_FILE..."
    echo "$CONDA_SETUP" >> "$BASHRC_FILE"
else
    echo "Conda initialization already present in $BASHRC_FILE. Skipping."
fi

# Step 7: Reload .bashrc so the changes take effect immediately
echo "Reloading .bashrc..."
source "$HOME/.bashrc"

# Step 8: Optional cleanup of the installer
echo "Cleaning up downloaded installer..."
rm -f "$INSTALLER_FILE"

# Final message
echo "Miniforge installed and initialization added to .bashrc. The environment is now ready!"
