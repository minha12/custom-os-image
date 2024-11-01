To configure **NVIDIA GPU Pass-Through** for **KVM** on your server running **Ubuntu 24.04** (or **Ubuntu 22.04**), follow these steps:

### 1. Install Prerequisites

You need to install necessary tools like `qemu-kvm`, `libvirt`, and `virt-manager`. Open a terminal and run:

```bash
sudo apt update
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager cloud-utils
```

Ensure that KVM is installed and the system supports virtualization:

```bash
sudo kvm-ok
```

You should see something like `KVM acceleration can be used` if it's supported.

**Add yourself to the necessary groups:**
   ```sh
   sudo adduser $USER libvirt
   sudo adduser $USER kvm
   newgrp libvirt
   newgrp kvm
   ```

**Ensure `libvirtd` service is running:**
   ```sh
   sudo systemctl start libvirtd
   sudo systemctl enable libvirtd
   ```
   
### 2. Verify IOMMU Support

Check if your system supports IOMMU by running:

```bash
sudo dmesg | grep -e DMAR -e IOMMU
```

If your system supports IOMMU, you should see related output.

#### Step 2.1: Enable IOMMU in the BIOS
You will need to enable IOMMU or VT-d (Intel) or AMD-Vi (AMD) in your BIOS.

#### Step 2.2: Enable IOMMU in Grub
Edit your Grub configuration:

```bash
sudo nano /etc/default/grub
```

For Intel systems, add `intel_iommu=on`, and for AMD systems, add `amd_iommu=on` to the `GRUB_CMDLINE_LINUX` line.

- For Intel:
    ```bash
    GRUB_CMDLINE_LINUX="intel_iommu=on"
    ```

- For AMD:
    ```bash
    GRUB_CMDLINE_LINUX="amd_iommu=on"
    ```

Update Grub:

```bash
sudo update-grub
```

Reboot your system:

```bash
sudo reboot
```

### 3. Configure NVIDIA vGPU or Passthrough

#### Step 3.1: Blacklist the NVIDIA Driver on Host

To prevent the host from using the NVIDIA GPU, you need to blacklist the NVIDIA driver:

```bash
sudo nano /etc/modprobe.d/blacklist-nvidia.conf
```

Add the following lines:

```bash
blacklist nouveau
blacklist lbm-nouveau
blacklist nvidia
blacklist nvidia-uvm
blacklist nvidia-modeset
blacklist nvidia-drm
```

Update initramfs:

```bash
sudo update-initramfs -u
```

Reboot the system:

```bash
sudo reboot
```

#### Step 3.2: Bind NVIDIA GPU to vfio-pci

To use the GPU for passthrough, bind it to the `vfio-pci` driver. First, identify the vendor and device IDs:

```bash
lspci -nnk | grep -i nvidia
```

You'll see output like this:

```
01:00.0 VGA compatible controller [0300]: NVIDIA Corporation Device [10de:1eb8] (rev a1)
01:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:10f9] (rev a1)
```

The IDs are `10de:1eb8` and `10de:10f9`. Use these to bind the GPU to `vfio-pci`.

Edit the `vfio.conf` file:

```bash
sudo nano /etc/modprobe.d/vfio.conf
```

Add the following line, replacing the IDs with those from your output:

```bash
options vfio-pci ids=10de:1eb8,10de:10f9
```

Update initramfs:

```bash
sudo update-initramfs -u
```

Reboot the system:

```bash
sudo reboot
```
