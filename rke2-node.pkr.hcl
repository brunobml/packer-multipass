packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "= 1.1.7"
    }
  }
}

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

variable "ssh_private_key_file" {
  type      = string
  sensitive = true
}

variable "accelerator" {
  type    = string
  default = "kvm"
}

variable "output_directory" {
  type    = string
  default = "output/rke2-node"
}

source "qemu" "rke2_node" {
  iso_url      = "https://cloud-images.ubuntu.com/noble/20261017/noble-server-cloudimg-amd64.img"
  iso_checksum = "sha256:04e8f2461a16a44e78a370284471f29616cdd9baf1893df25807b71f985b6c94"

  disk_image       = true
  accelerator      = var.accelerator
  format           = "qcow2"
  disk_size        = "16000M"
  disk_interface   = "virtio"
  net_device       = "virtio-net"
  cpus             = 2
  memory           = 2048
  headless         = true
  output_directory = var.output_directory
  vm_name          = "rke2-node.qcow2"

  cd_label = "cidata"
  cd_content = {
    "meta-data" = "instance-id: packer-rke2-node\nlocal-hostname: packer-rke2-node\n"
    "user-data" = templatefile("${path.root}/cloud-init/user-data.yaml.tftpl", {
      ssh_public_key = var.ssh_public_key
    })
  }

  ssh_username         = "ubuntu"
  ssh_private_key_file = var.ssh_private_key_file
  ssh_timeout          = "15m"
  shutdown_command     = "sudo bash /tmp/packer-cleanup.sh && sudo shutdown -P now"
}

build {
  sources = ["source.qemu.rke2_node"]

  provisioner "shell" {
    script          = "scripts/provision.sh"
    execute_command = "chmod +x {{ .Path }}; sudo env DEBIAN_FRONTEND=noninteractive {{ .Path }}"
  }

  provisioner "file" {
    source      = "scripts/cleanup.sh"
    destination = "/tmp/packer-cleanup.sh"
  }
}
