#!/bin/bash

set -eu
set -o pipefail

PATCH_GITHUB_USER=""
PATCH_HASH=""

if [[ $KERNEL_VERSION == *"-rc"* ]]; then
    KERNEL_URL="https://git.kernel.org/torvalds/t/linux-${KERNEL_VERSION}.tar.gz"
elif [[ $KERNEL_VERSION == *"-patch"* ]]; then
    KERNEL_URL="https://git.kernel.org/torvalds/t/linux-${KERNEL_VERSION%-patch-*}.tar.gz"
    # Extract GitHub user and commit hash from format: version-patch-user-hash
    PATCH_INFO="${KERNEL_VERSION##*-patch-}"
    PATCH_GITHUB_USER="${PATCH_INFO%%-*}"
    PATCH_HASH="${PATCH_INFO#*-}"
else
    KERNEL_MAJ_VERSION=$(echo "$KERNEL_VERSION" | cut -d '.' -f 1)
    KERNEL_URL="https://www.kernel.org/pub/linux/kernel/v${KERNEL_MAJ_VERSION}.x/linux-${KERNEL_VERSION}.tar.xz"
fi

cd /tmp/kernel
curl --fail -L --time-cond "linux-${KERNEL_VERSION}.tar.${KERNEL_URL##*.}" -o "linux-${KERNEL_VERSION}.tar.${KERNEL_URL##*.}" "$KERNEL_URL"
mkdir /usr/src/linux
tar -xf "linux-${KERNEL_VERSION}.tar.${KERNEL_URL##*.}" --strip-components=1 -C /usr/src/linux

if [[ -n "$PATCH_HASH" ]]; then
    cd /usr/src/linux
    curl --fail -L -o "/tmp/kernel/patch.patch" "https://github.com/${PATCH_GITHUB_USER}/linux/commit/${PATCH_HASH}.patch"
    patch -p1 < "/tmp/kernel/patch.patch"
fi