#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/common.sh"
load_env

VM_USERNAME=${VM_USERNAME:-$DEFAULT_VM_USERNAME}
IP_ADDR=${IP_ADDR:-$DEFAULT_IP}
VM_NAME=${VM_NAME:-$DEFAULT_VM_NAME}
UBUNTU_RELEASE=${DEFAULT_UBUNTU_RELEASE}
VM_IMAGE_DIR=${VM_IMAGE_DIR:-"/var/lib/libvirt/images"}
OUTPUT_DIR=${OUTPUT_DIR:-"/var/lib/libvirt/images"}

# Ensure required tools are installed
if ! command -v qemu-img &> /dev/null; then
    echo "qemu-img could not be found. Installing..."
    sudo apt-get update
    sudo apt-get install -y qemu-utils
fi

if ! command -v virt-sparsify &> /dev/null; then
    echo "virt-sparsify could not be found. Installing..."
    sudo apt-get update
    sudo apt-get install -y libguestfs-tools
fi

# Shutdown the VM after cleanup
echo "Shutting down VM $VM_NAME..."
ssh "$VM_USERNAME@$IP_ADDR" "sudo shutdown -h now"

# Wait for the VM to shut down completely
echo "Waiting for VM to shut down..."
while sudo virsh domstate "$VM_NAME" | grep -q running; do
    sleep 5
done
echo "VM is now shut down."

# Packing VM to OS image
echo "Converting VM image to OS image..."
sudo qemu-img convert -O qcow2 "${VM_IMAGE_DIR}/${VM_NAME}.qcow2" \
    "${OUTPUT_DIR}/${UBUNTU_RELEASE}-server-cloudimg-nvidia.qcow2"

# Sparsify the image
echo "Sparsifying the image..."
sudo virt-sparsify --compress "${OUTPUT_DIR}/${UBUNTU_RELEASE}-server-cloudimg-nvidia.qcow2" \
    "${OUTPUT_DIR}/${UBUNTU_RELEASE}-server-cloudimg-nvidia-sparsified.qcow2"

echo "Image packaging completed. Output image: ${OUTPUT_DIR}/${UBUNTU_RELEASE}-server-cloudimg-nvidia-sparsified.qcow2"
