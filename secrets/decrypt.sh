#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Function to find the age key
find_key() {
    if [ -f key.txt ]; then
        echo "key.txt"
    elif [ -f /var/lib/sops-nix/key.txt ]; then
        echo "/var/lib/sops-nix/key.txt"
    else
        echo ""
    fi
}

KEY_PATH=$(find_key)

# Check if key exists anywhere
if [ -z "$KEY_PATH" ]; then
    echo "Error: No key found in either ./key.txt or /var/lib/sops-nix/key.txt"
    echo "Please run ./encrypt.sh first to generate a key"
    exit 1
fi

# Check if encrypted secrets exist
if [ ! -f secrets.yaml ]; then
    echo "Error: secrets.yaml not found. Please copy secrets.yaml.example and run ./encrypt.sh first"
    exit 1
fi

# Decrypt secrets to working file and remove any nested data structures
SOPS_AGE_KEY_FILE="$KEY_PATH" SOPS_CONFIG=.sops.yaml sops --input-type=yaml --output-type=yaml -d secrets.yaml > secrets.yaml.work
echo "Decrypted secrets.yaml to secrets.yaml.work"
echo "IMPORTANT: Edit secrets.yaml.work, then run ./encrypt.sh to save changes" 