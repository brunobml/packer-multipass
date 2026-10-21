#!/usr/bin/env bash
set -euo pipefail

cloud-init clean --logs --seed --machine-id
rm -f /etc/ssh/ssh_host_*
rm -f /home/ubuntu/.ssh/authorized_keys
rm -f /tmp/packer-cleanup.sh
apt-get clean
rm -rf /var/lib/apt/lists/*
