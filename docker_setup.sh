#!/bin/bash

# Generate SSH keys for the server
cd ssh_keys
ssh-keygen -t ed25519 -f ssh_host_ed25519_key < /dev/null
ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key < /dev/null
cd ..


# Set the correct permissions for the SSH keys
sudo chmod 700 ssh_keys
sudo chmod 600 ssh_keys/ssh_host_ed25519_key ssh_keys/ssh_host_rsa_key
sudo chmod 644 ssh_keys/*.pub

