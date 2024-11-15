
# OS Image Customization Pipeline

This repository provides a pipeline for creating and customizing OS images with pre-installed software and drivers. It is primarily used for preparing images that include NVIDIA GPU drivers, CUDA, and various software packages for remote desktop access, data science, and machine learning.

The pipeline automates the creation of VM-based OS images, installs necessary software components, and packages the image for deployment or reuse. The customized images are designed to be used in environments where GPU acceleration and machine learning frameworks are essential.

## **Prerequisites**

- Ubuntu Server 24.04 (tested on 22.04, 24.04) host machine
- NVIDIA GPUs with compatible drivers
- Internet connection with access to required repositories
- `qemu`, `libvirt`, `virt-manager`, `wget`, `ssh`, `cloud-image-utils`, and other dependencies
- Referring to `Configuring-gpu-passthrough.md` for NVIDIA GPU passthrough on host machine
## **Directory Structure**

```
project-root/
├── scripts/
│   ├── common.sh
│   ├── create_vm_maas_nvidia.sh
│   ├── setup_software_and_clean.sh
│   ├── install_cuda_12_4.sh
│   ├── clean_up.sh
│   └── packing_os_images.sh
├── configs/
│   ├── user-data-template.yaml
│   ├── network-config-template.yaml
│   └── meta-data-template.yaml
├── .env
├── README.md
└── .gitignore
```

## **Setup Instructions**

### **1. Clone the Repository**

```bash
git clone https://github.com/minha12/custom-os-image.git
cd custom-os-image
```

### **2. Configure Environment Variables**

Edit the `.env` file to match your environment:

```dotenv
DEFAULT_INTERFACE="enp1s0"
DEFAULT_IP="192.168.122.101"
DEFAULT_VM_NAME="vm01"
DEFAULT_UBUNTU_RELEASE="jammy"
DEFAULT_RAM=4096
DEFAULT_VCPUS=4
DEFAULT_DISK_SIZE="50G"
DEFAULT_DOWNLOAD_IMAGE=true
DEFAULT_GPU_DEVICES=("4a:00.0" "61:00.0" "ca:00.0" "e1:00.0")
DEFAULT_VM_USERNAME="ubuntu"
DEFAULT_VM_PASSWORD="ubuntu"
DEFAULT_HTTP_PROXY="http://192.168.115.2:8000"
DEFAULT_NO_PROXY="localhost,127.0.0.1,*.local,192.168.0.0/16"
```

## **Making Scripts Executable**

Ensure all scripts are executable:

```bash
chmod +x scripts/*.sh
```


### **3. Run the VM Creation Script**

```bash
bash scripts/create_vm_maas_nvidia.sh
```

This script will:

- Create a VM with specified configurations.
- Set up cloud-init with user data and network configurations.
- Start the VM with NVIDIA GPU passthrough.

### **4. Set Up Software Inside the VM**

```bash
bash scripts/setup_software_and_clean.sh
```

This script will:

- Wait for the VM to become reachable via SSH.
- Install NVIDIA drivers and CUDA toolkit.
- Clean up temporary files inside the VM.

### **5. Package the VM Image**

```bash
bash scripts/packing_os_images.sh
```

This script will:

- Shut down the VM.
- Convert and sparsify the VM image.
- Prepare the image for deployment or distribution.

## **Scripts Overview**

- **`create_vm_maas_nvidia.sh`**: Creates the VM with GPU passthrough.
- **`setup_software_and_clean.sh`**: Installs necessary software in the VM.
- **`install_cuda_12_4.sh`**: Installs CUDA Toolkit 12.4 inside the VM.
- **`clean_up.sh`**: Cleans temporary files inside the VM.
- **`packing_os_images.sh`**: Packages the VM image for reuse.
- **`common.sh`**: Contains common functions used by other scripts.

## **Running Remote Desktop with XFCE and TightVPN**
- Run `sudo chown -R ubuntu:ubuntu ~/.vnc`
- If vpn at server side haven't started: `vncserver :1`
- Install `RealVNC` at client side
- Run ssh port forwarding at client side: `ssh -L 5901:localhost:5901 <vm_user>@<vm_IP>` (if there is a jumpy host: `ssh -L 5901:localhost:5901 -o 'ProxyJump sshuser@130.236.99.215' ubuntu@<vm_ip>`)
- Enter `localhost:5901` on Real VNC

## **Running Jupter Lab**
- ssh to the VM, run `conda activate`
- Run: `nohup jupyter lab --ip=0.0.0.0 --port=8888 --no-browser &`
- `cat nohup.out `: looking for token
- At client side: `ssh -NfL localhost:8888:localhost:8888 <vm_user>@vm_IP` (if there is a jump host: `ssh -NfL localhost:8888:localhost:8888 -o 'ProxyJump sshuser@130.236.99.215' ubuntu@vm_ip`)

## **Configuration Files**

- **`user-data-template.yaml`**: Cloud-init user data template.
- **`network-config-template.yaml`**: Cloud-init network configuration template.
- **`meta-data-template.yaml`**: Cloud-init meta-data template.

## **Notes**

- Ensure that your host machine's BIOS is configured for virtualization and IOMMU is enabled.
- Adjust GPU device IDs in the `.env` file to match your hardware.
- The scripts assume a certain network configuration; you may need to adjust the network settings in the `.env` file and templates.

## **License**

This project is licensed under the MIT License.

