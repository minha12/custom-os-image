#!/bin/bash
set -euo pipefail

# Function to check and generate SSH key if not exists
function check_ssh_key() {
    if ! [ -f ~/.ssh/id_rsa ]; then
        ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
        echo "SSH key generated."
    fi
}

# Function to wait for SSH to become available
function wait_for_ssh() {
    local ip_addr=$1
    echo "Waiting for SSH to become ready on $ip_addr..."
    while ! nc -z "$ip_addr" 22; do
        echo "SSH service not ready on $ip_addr. Waiting..."
        sleep 5
    done
    echo "SSH service detected on $ip_addr."
}

# Function to load environment variables from .env
function load_env() {
    if [ -f "$(dirname "$0")/../.env" ]; then
        set -o allexport
        source "$(dirname "$0")/../.env"
        set +o allexport
    else
        echo ".env file not found!"
        exit 1
    fi
    
    # Reconstruct DEFAULT_GPU_DEVICES as an array, handle empty array
    if [ -z "${DEFAULT_GPU_DEVICES:-}" ]; then
        DEFAULT_GPU_DEVICES=()
    else
        IFS=',' read -r -a DEFAULT_GPU_DEVICES <<< "${DEFAULT_GPU_DEVICES//[()]/}"
    fi
}


load_env
