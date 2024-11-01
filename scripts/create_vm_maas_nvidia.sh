#!/bin/bash
set -euo pipefail

# Load environment variables
source "$(dirname "$0")/common.sh"
load_env

# Set default values from .env or use provided arguments
VM_NAME=${1:-$DEFAULT_VM_NAME}
DOWNLOAD_IMAGE=${DOWNLOAD_IMAGE:-$DEFAULT_DOWNLOAD_IMAGE}
EXISTING_IMAGE_PATH=${EXISTING_IMAGE_PATH:-""}
INTERFACE=${DEFAULT_INTERFACE}
IP_ADDR=${DEFAULT_IP}
UBUNTU_RELEASE=${DEFAULT_UBUNTU_RELEASE}
RAM=${DEFAULT_RAM}
VCPUS=${DEFAULT_VCPUS}
DISK_SIZE=${DEFAULT_DISK_SIZE}
GPU_DEVICES=("${DEFAULT_GPU_DEVICES[@]}")
#GPU_DEVICES=${DEFAULT_GPU_DEVICES}
VM_USERNAME=${DEFAULT_VM_USERNAME}
VM_PASSWORD=${DEFAULT_VM_PASSWORD}
HTTP_PROXY=${DEFAULT_HTTP_PROXY}
NO_PROXY=${DEFAULT_NO_PROXY}
VM_IMAGE_DIR=${VM_IMAGE_DIR:-"/var/lib/libvirt/images"}

# Convert GPU_DEVICES to an array
IFS=' ' read -r -a GPU_DEVICES_ARRAY <<< "${GPU_DEVICES:-}"

# Generate a random MAC address
MAC_ADDR=$(printf '52:54:00:%02x:%02x:%02x' $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)))

# Check required variables
if [ -z "$VM_NAME" ] || [ -z "$UBUNTU_RELEASE" ] || [ -z "$DISK_SIZE" ]; then
    echo "Error: VM_NAME, UBUNTU_RELEASE, and DISK_SIZE must be set."
    exit 1
fi

# Prevent running script as root
if [ "$EUID" -eq 0 ]; then
    echo "Please do not run this script as root or with sudo."
    exit 1
fi

# Set up paths
VM_IMAGE="${VM_IMAGE_DIR}/${VM_NAME}.qcow2"
SEED_IMAGE="${VM_IMAGE_DIR}/${VM_NAME}-seed.qcow2"

# Create temporary working directory
WORK_DIR=$(mktemp -d)
echo "Using temporary working directory: $WORK_DIR"

# Ensure WORK_DIR exists
if [ ! -d "$WORK_DIR" ]; then
    echo "Error: Failed to create temporary working directory."
    exit 1
fi

# Determine VM Image
if [ "$DOWNLOAD_IMAGE" = true ] || [ "$DOWNLOAD_IMAGE" = "true" ]; then
    DOWNLOAD_VM_IMAGE="${UBUNTU_RELEASE}-server-cloudimg-amd64.img"
    UBUNTU_IMAGE_URL="https://cloud-images.ubuntu.com/${UBUNTU_RELEASE}/current/${DOWNLOAD_VM_IMAGE}"
    # Download Ubuntu cloud image using the proxy settings
    if [ ! -f "$DOWNLOAD_VM_IMAGE" ]; then
        wget -e use_proxy=yes -e http_proxy="$HTTP_PROXY" -e https_proxy="$HTTP_PROXY" "$UBUNTU_IMAGE_URL"
    fi
    # Copy the image to VM_IMAGE_DIR
    sudo cp "$DOWNLOAD_VM_IMAGE" "$VM_IMAGE_DIR/"
    BACKING_IMAGE="$VM_IMAGE_DIR/$DOWNLOAD_VM_IMAGE"
    # Ensure BACKING_IMAGE exists
    if [ ! -f "$BACKING_IMAGE" ]; then
        echo "Error: Backing image $BACKING_IMAGE not found."
        exit 1
    fi
    # Set permissions
    sudo chown libvirt-qemu:kvm "$BACKING_IMAGE"
    sudo chmod 644 "$BACKING_IMAGE"
    # Create disk image
    sudo qemu-img create -f qcow2 -F qcow2 -b "$BACKING_IMAGE" "$VM_IMAGE" "$DISK_SIZE"
else
    if [ -z "$EXISTING_IMAGE_PATH" ]; then
        echo "Existing image path must be provided if DOWNLOAD_IMAGE is false."
        exit 1
    fi
    VM_IMAGE="$EXISTING_IMAGE_PATH"
    # Resize existing image
    sudo qemu-img resize "$VM_IMAGE" "$DISK_SIZE"
fi

# Ensure VM_IMAGE exists
if [ ! -f "$VM_IMAGE" ]; then
    echo "Error: VM image $VM_IMAGE not found."
    exit 1
fi

# Set permissions
sudo chown libvirt-qemu:kvm "$VM_IMAGE"
sudo chmod 644 "$VM_IMAGE"

# Generate SSH key if not exists
check_ssh_key

# Read the public key
SSH_PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)

# Create cloud-init config files using templates
# Install envsubst if not installed
if ! command -v envsubst &> /dev/null; then
    echo "envsubst not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y gettext-base
fi

# Export variables for envsubst
export VM_NAME VM_USERNAME VM_PASSWORD HTTP_PROXY HTTPS_PROXY NO_PROXY SSH_PUBLIC_KEY MAC_ADDR INTERFACE IP_ADDR

# Generate user-data
envsubst < "$(dirname "$0")/../configs/user-data-template.yaml" > "$WORK_DIR/user-data"

# Generate network-config
envsubst < "$(dirname "$0")/../configs/network-config-template.yaml" > "$WORK_DIR/network-config"

# Generate meta-data
envsubst < "$(dirname "$0")/../configs/meta-data-template.yaml" > "$WORK_DIR/meta-data"

# Create the cloud-init ISO with proper permissions
sudo cloud-localds -v --network-config="$WORK_DIR/network-config" "$SEED_IMAGE" "$WORK_DIR/user-data" "$WORK_DIR/meta-data"
sudo chown libvirt-qemu:kvm "$SEED_IMAGE"
sudo chmod 644 "$SEED_IMAGE"

# Ensure SEED_IMAGE exists
if [ ! -f "$SEED_IMAGE" ]; then
    echo "Error: Seed image $SEED_IMAGE not found."
    exit 1
fi

# GPU Options
GPU_OPTIONS=""
for device in "${GPU_DEVICES_ARRAY[@]}"; do
    GPU_OPTIONS="$GPU_OPTIONS --host-device $device"
done
GPU_OPTIONS="$GPU_OPTIONS --features kvm_hidden=on"

# Create and start the VM
sudo virt-install --connect qemu:///system \
  --virt-type kvm \
  --name "$VM_NAME" \
  --ram "$RAM" \
  --vcpus "$VCPUS" \
  --os-variant ubuntu22.04 \
  --disk path="$VM_IMAGE",device=disk \
  --disk path="$SEED_IMAGE",device=cdrom \
  --network network=default,model=virtio,mac="$MAC_ADDR" \
  --import \
  $GPU_OPTIONS \
  --noautoconsole

# List all VMs
echo "Listing all VMs:"
sudo virsh list --all

# Clean up temporary working directory
if [[ -d "$WORK_DIR" && "$WORK_DIR" == /tmp/* ]]; then
    rm -rf "$WORK_DIR"
else
    echo "Warning: Temporary working directory $WORK_DIR not removed because it is outside /tmp"
fi

# End of script
echo "VM $VM_NAME created successfully."
