#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_dir"

if ! command -v packer >/dev/null 2>&1 && [[ -x "$repo_dir/.tools/packer" ]]; then
    PATH="$repo_dir/.tools:$PATH"
fi
if ! command -v xorriso >/dev/null 2>&1 && ! command -v mkisofs >/dev/null 2>&1 && [[ -x "$repo_dir/.tools/usr/bin/mkisofs" ]]; then
    PATH="$repo_dir/.tools/usr/bin:$PATH"
fi
for required_command in packer qemu-system-x86_64 qemu-img ssh-keygen; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$required_command" >&2
        exit 1
    fi
done
if ! command -v xorriso >/dev/null 2>&1 && ! command -v mkisofs >/dev/null 2>&1; then
    printf 'Install xorriso or genisoimage before building.\n' >&2
    exit 1
fi
if [[ -e output/rke2-node ]]; then
    printf 'output/rke2-node already exists; archive or remove it before rebuilding.\n' >&2
    exit 1
fi

accelerator=kvm
if [[ ! -r /dev/kvm || ! -w /dev/kvm ]]; then
    accelerator=tcg
    printf 'KVM is unavailable to this user; building with slower QEMU software emulation.\n' >&2
fi

build_key_dir=$(mktemp -d)
trap 'unlink "$build_key_dir/packer-key"; unlink "$build_key_dir/packer-key.pub"; rmdir "$build_key_dir"' EXIT
ssh-keygen -q -t ed25519 -N '' -f "$build_key_dir/packer-key"

packer init .
packer validate \
    -var "accelerator=$accelerator" \
    -var "ssh_public_key=$(cat "$build_key_dir/packer-key.pub")" \
    -var "ssh_private_key_file=$build_key_dir/packer-key" \
    .
packer build \
    -var "accelerator=$accelerator" \
    -var "ssh_public_key=$(cat "$build_key_dir/packer-key.pub")" \
    -var "ssh_private_key_file=$build_key_dir/packer-key" \
    .
