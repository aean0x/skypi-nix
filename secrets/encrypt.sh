#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Generate age key if it doesn't exist
if [ ! -f key.txt ]; then
    age-keygen -o key.txt
    echo "Generated new age key in key.txt"
    echo "Public key:"
    age-keygen -y key.txt
fi

# Create .sops.yaml if it doesn't exist
if [ ! -f ../.sops.yaml ]; then
    PUBLIC_KEY=$(age-keygen -y key.txt)
    cat > ../.sops.yaml << EOF
creation_rules:
  - path_regex: secrets/secrets\.yaml$
    key_groups:
      - age:
          - ${PUBLIC_KEY}
EOF
    echo "Created .sops.yaml with your public key"
fi

# Encrypt secrets if they exist
if [ -f secrets.yaml ]; then
    SOPS_AGE_KEY_FILE=key.txt sops -e -i secrets.yaml
    echo "Encrypted secrets.yaml"
else
    echo "Please copy secrets.yaml.example to secrets.yaml and fill in your values first"
    exit 1
fi 