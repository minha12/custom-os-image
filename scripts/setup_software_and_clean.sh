#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/common.sh"
load_env

VM_USERNAME=${VM_USERNAME:-$DEFAULT_VM_USERNAME}
IP_ADDR=${IP_ADDR:-$DEFAULT_IP}
VM_NAME=${VM_NAME:-$DEFAULT_VM_NAME}

check_ssh_key

# Wait for the VM to become reachable via ping
echo "Waiting for VM $VM_NAME to become reachable at $IP_ADDR..."
while ! ping -c 1 "$IP_ADDR" &> /dev/null; do
    echo "VM is not yet reachable. Waiting..."
    sleep 5
done
echo "VM is now reachable by ping."

# Wait for SSH
wait_for_ssh "$IP_ADDR"

# Clear out any existing key for the VM's IP
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$IP_ADDR"
# Add the current VM's key to known_hosts
ssh-keyscan -H "$IP_ADDR" >> "$HOME/.ssh/known_hosts"

# Start SSH connection
echo "Attempting SSH connection to $VM_USERNAME@$IP_ADDR..."
while ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$VM_USERNAME@$IP_ADDR" true; do
    echo "SSH is not ready. Waiting..."
    sleep 5
done
echo "SSH connection established."

# Copy scripts to VM
echo "Copying install scripts to VM..."
scp "$(dirname "$0")/install_miniforge.sh"  "$(dirname "$0")/install_cuda_12_4.sh" "$(dirname "$0")/clean_up.sh" "$VM_USERNAME@$IP_ADDR:/tmp/"

# Set execute permissions
echo "Setting execute permissions on scripts inside VM..."
ssh "$VM_USERNAME@$IP_ADDR" 'sudo chmod +x /tmp/install_miniforge.sh && sudo chmod +x /tmp/install_cuda_12_4.sh && sudo chmod +x /tmp/clean_up.sh'

# Run scripts with sudo
ssh "$VM_USERNAME@$IP_ADDR" '
    set -e;
    
    # Install Miniforge
    echo "Installing Miniforge...";
    if ! /tmp/install_miniforge.sh; then
        echo "Error: Miniforge installation failed";
        # Do not stop script entirely, proceed to CUDA installation
    fi

    # Install CUDA
    echo "Installing CUDA...";
    if ! sudo /tmp/install_cuda_12_4.sh; then
        echo "Error: CUDA installation failed";
        # Proceed to cleanup anyhow
    fi

    # Clean up operations
    echo "Running cleanup...";
    if ! sudo /tmp/clean_up.sh; then
        echo "Error: Cleanup failed";
    fi

    echo "All tasks complete!";
'

echo "Software setup and cleanup completed on VM $VM_NAME."
