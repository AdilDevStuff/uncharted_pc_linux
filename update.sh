#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Auto-updater script for Uncharted: The Nathan Drake Collection (Linux port).
# Checks upstream (Supermedo/uncharted_pc) and origin for updates, merges them,
# updates submodules and patches, and rebuilds the native Linux binaries.

set -euo pipefail
cd -- "$(dirname -- "$0")"

UPSTREAM_URL="https://github.com/Supermedo/uncharted_pc.git"
ORIGIN_URL="https://github.com/AdilDevStuff/uncharted_pc_linux.git"

echo "========================================================"
echo "  Uncharted Linux Port - Auto Updater & Rebuilder"
echo "========================================================"

# 1. Ensure git repository
if [[ ! -d .git ]]; then
    echo "ERROR: Not a git repository. Cannot update code." >&2
    exit 1
fi

# 2. Ensure upstream remote exists
if ! git remote get-url upstream &>/dev/null; then
    echo "Adding upstream remote: $UPSTREAM_URL"
    git remote add upstream "$UPSTREAM_URL"
fi

# 3. Fetch latest from upstream and origin
echo "Checking for updates from upstream ($UPSTREAM_URL)..."
git fetch upstream main --quiet || {
    echo "WARNING: Could not fetch from upstream. Trying origin..."
}

echo "Checking for updates from origin ($ORIGIN_URL)..."
git fetch origin main --quiet || true

# 4. Check if upstream or origin has new commits
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
    echo "Notice: Current branch is '$CURRENT_BRANCH', not 'main'."
fi

UPSTREAM_COMMITS=$(git rev-list --count HEAD..upstream/main 2>/dev/null || echo 0)
ORIGIN_COMMITS=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo 0)

UPDATED=0
if [[ "$UPSTREAM_COMMITS" -gt 0 ]]; then
    echo "Found $UPSTREAM_COMMITS new commit(s) from upstream!"
    echo "Merging upstream updates..."
    git merge upstream/main --no-edit -m "Merge upstream updates from Supermedo/uncharted_pc" || {
        echo "WARNING: Automatic merge had conflicts. Attempting automatic resolution..."
        # In case of minor conflicts in README or windows packaging, prefer ours
        git checkout --ours README.md 2>/dev/null || true
        git add README.md 2>/dev/null || true
        git commit -m "Merge upstream updates with Linux compatibility preserved" || true
    }
    UPDATED=1
elif [[ "$ORIGIN_COMMITS" -gt 0 ]]; then
    echo "Found $ORIGIN_COMMITS new commit(s) from origin!"
    echo "Pulling updates..."
    git merge origin/main --no-edit
    UPDATED=1
else
    echo "Repository code is up to date."
fi

# 5. Ensure submodules are up to date
echo "Updating git submodules..."
git submodule update --init --recursive

# 6. Apply any FSR-Vulkan patches if needed
if [[ -d gpu/patches/fsr-vulkan && -d gpu/third_party/fsr-vulkan ]]; then
    for patch in gpu/patches/fsr-vulkan/*.patch; do
        if [[ -f "$patch" ]] && ! git -C gpu/third_party/fsr-vulkan apply --reverse --check "$PWD/$patch" 2>/dev/null; then
            git -C gpu/third_party/fsr-vulkan apply "$PWD/$patch" 2>/dev/null || true
        fi
    done
fi

# 7. Rebuild native binaries if updated or requested
if [[ "$UPDATED" -eq 1 || ! -f out/bb-probe || "${1:-}" == "--force" || "${1:-}" == "--rebuild" ]]; then
    echo "Building native Linux binaries..."
    bash build.sh
    echo "========================================================"
    echo " Update and build completed successfully!"
    echo "========================================================"
else
    echo "Native binaries are already built and up to date."
    echo "Run './update.sh --rebuild' to force recompilation."
fi
