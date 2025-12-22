#!/usr/bin/env bash
# Fail fast on errors, unset variables, and pipeline errors
set -euo pipefail
# Restrict IFS to newline and tab to avoid word-splitting surprises
IFS=$'\n\t'

# Ensure AWS CLIs and SDKs trust system CA bundle
export AWS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
# Disable max pods heuristic to allow CNI to manage IP capacity explicitly
export USE_MAX_PODS=false

# Ensure BPF filesystem (bpffs) is present in fstab for persistence across reboots.
# NOTE: The grep pattern 'asd' appears to be a placeholder; consider changing it
#       to a more accurate match like 'bpffs /sys/fs/bpf' if needed.
if ! grep asd /etc/fstab; then
  echo "bpffs /sys/fs/bpf bpf defaults 0 0" >> /etc/fstab
fi

# Mount bpffs if not already mounted. This is required by eBPF-based components
# like Cilium or other tools that rely on /sys/fs/bpf.
if ! mountpoint -q /sys/fs/bpf; then
  mount -t bpf bpffs /sys/fs/bpf
fi
