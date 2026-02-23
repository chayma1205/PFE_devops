#!/bin/bash

# ensure .ssh directory exists with correct permissions
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh

# tf will replace ${private_key} with the content of key.pem
cat > /home/ubuntu/.ssh/id_rsa << 'EOF'
${private_key}
EOF

# set permissions
chmod 400 /home/ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu /home/ubuntu/.ssh

# --- custom user data ---
set -eux

# Update package index
apt update

# Install required packages
apt install -y ca-certificates curl gnupg lsb-release

# Create keyrings directory
install -m 0755 -d /etc/apt/keyrings

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
apt update

# Install Docker Engine, CLI, containerd, and Compose plugin
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Add ubuntu user to docker group (so you don’t need sudo)
usermod -aG docker ubuntu

git clone https://github.com/maissen/todo_app.git
cd todo_app/db
sudo docker compose up -d

# Install aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

sudo apt-get update && sudo apt-get install -y unzip

unzip awscliv2.zip

sudo ./aws/install