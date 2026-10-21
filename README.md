# Multipass golden image for RKE2 nodes

This Packer project builds a reusable Ubuntu 24.04 QCOW2 image for RKE2 cluster nodes. It installs common OS tools, enables the kernel modules and networking settings used by Kubernetes, and leaves cloud-init ready to customize each new VM. It does **not** install or start RKE2, create cluster tokens, or initialize etcd. Those belong in the cluster deployment stage.

## Build the image

Run this on Linux with [Packer](https://developer.hashicorp.com/packer/install), QEMU, `mkisofs` (from `genisoimage`) or `xorriso`, and `ssh-keygen`. The script installs the pinned [HashiCorp QEMU plugin](https://developer.hashicorp.com/packer/integrations/hashicorp/qemu/latest/components/builder/qemu). KVM access makes the build much faster; the script falls back to QEMU software emulation when it is unavailable. The build uses the dated Ubuntu 24.04 amd64 cloud image from 2026-10-17 and verifies its SHA256 digest.

On Ubuntu, install the system prerequisites with:

```bash
sudo apt-get install -y qemu-system-x86 qemu-utils genisoimage openssh-client
```

Install Packer using HashiCorp's linked instructions. A local Packer binary at `.tools/packer` also works; `.tools` is ignored by Git.

```bash
bash ./scripts/build.sh
```

The script creates a temporary SSH key, installs the pinned Packer plugin, validates the template, and writes `output/rke2-node/rke2-node.qcow2`. The temporary key is removed after the build. The image has a 16 GB virtual disk; the tested QCOW2 artifact used about 2.3 GB on the host. The build can take several minutes while Ubuntu packages upgrade.

## Test the artifact in Multipass

Multipass custom images require a Linux host. From this directory:

```bash
multipass launch "file://$PWD/output/rke2-node/rke2-node.qcow2" \
  --name rke2-image-test --cpus 2 --memory 2G --disk 16G
multipass exec rke2-image-test -- cloud-init status --wait --long
multipass exec rke2-image-test -- bash -lc 'test "$(cat /proc/sys/net/ipv4/ip_forward)" = 1 && command -v python3 && command -v curl'
```

Use the same image path to launch five individually named instances. Each instance gets its own first boot cloud-init run. Provide per-instance access and role configuration with cloud-init or Ansible, then use Ansible to install RKE2, initialize three servers, and join two agents. An HA RKE2 cluster also needs a stable registration endpoint ahead of the servers.

The build cleans cloud-init state, machine ID, SSH host keys, and the temporary Packer SSH authorization before the image is shut down. Two test VMs launched from this image received distinct machine IDs and SSH host keys.

## Rebuild

To make an updated image, change the dated Ubuntu image URL and matching SHA256 in `rke2-node.pkr.hcl`, remove or archive the old `output/rke2-node` directory, then run the build again. The generated image and local tools are ignored by Git.
