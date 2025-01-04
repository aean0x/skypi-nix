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

# Generate age key if it doesn't exist anywhere
if [ -z "$KEY_PATH" ]; then
    echo "No key found in either ./key.txt or /var/lib/sops-nix/key.txt"
    echo "Generating new age key in key.txt"
    age-keygen -o key.txt
    KEY_PATH="key.txt"
    echo "Public key:"
    age-keygen -y key.txt
    echo
fi

# Offer to copy key to system location if it's not there
if [ -f key.txt ] && [ ! -f /var/lib/sops-nix/key.txt ]; then
    echo "Would you like to copy the key to /var/lib/sops-nix/key.txt? (required for NixOS) [y/N] "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        sudo mkdir -p /var/lib/sops-nix
        sudo cp key.txt /var/lib/sops-nix/key.txt
        sudo chmod 600 /var/lib/sops-nix/key.txt
        echo "Key copied to /var/lib/sops-nix/key.txt"
    else
        echo "REMINDER: You will need to manually copy key.txt to /var/lib/sops-nix/key.txt for NixOS to use these secrets"
    fi
fi

# Create .sops.yaml if it doesn't exist
if [ ! -f .sops.yaml ]; then
    PUBLIC_KEY=$(age-keygen -y "$KEY_PATH")
    cat > .sops.yaml << EOF
creation_rules:
  - path_regex: .*secrets\.yaml(\.work)?$
    key_groups:
      - age:
          - ${PUBLIC_KEY}
EOF
    echo "Created .sops.yaml with your public key"
fi

# Check if we have a working file or need to copy from example
if [ ! -f secrets.yaml.work ]; then
    if [ ! -f secrets.yaml ]; then
        if [ -f secrets.yaml.example ]; then
            cp secrets.yaml.example secrets.yaml.work
            echo "Created working file from example. Please edit secrets.yaml.work with your values"
            exit 0
        else
            echo "Error: Neither secrets.yaml.work nor secrets.yaml.example found"
            exit 1
        fi
    else
        # If we have an encrypted file, decrypt it to work file
        SOPS_AGE_KEY_FILE="$KEY_PATH" SOPS_CONFIG="$(pwd)/.sops.yaml" sops -d secrets.yaml > secrets.yaml.work
        echo "Created working file from existing encrypted secrets"
    fi
fi

# Encrypt the working file to the final location
if [ -f secrets.yaml.work ]; then
    SOPS_AGE_KEY_FILE="$KEY_PATH" SOPS_CONFIG="$(pwd)/.sops.yaml" sops -e secrets.yaml.work > secrets.yaml
    echo "Encrypted secrets.yaml.work to secrets.yaml"
    rm secrets.yaml.work
    echo "Removed working file"
else
    echo "Error: No secrets.yaml.work file found to encrypt"
    exit 1
fi 