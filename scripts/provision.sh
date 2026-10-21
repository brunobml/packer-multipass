#!/usr/bin/env bash
set -euo pipefail

cloud-init status --wait
apt-get update
apt-get upgrade -y
apt-get install -y ca-certificates curl jq python3 qemu-guest-agent

cat > /etc/modules-load.d/rke2.conf <<'EOF'
overlay
br_netfilter
EOF

cat > /etc/sysctl.d/90-rke2.conf <<'EOF'
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

modprobe overlay
modprobe br_netfilter
sysctl --system
