#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "This script requires sudo privileges"
  exit 1
fi

# Upgrade packages
dnf -y up

# Install Docker
dnf install -y dnf-utils zip unzip
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf remove -y runc
dnf install -y docker-ce --nobest
systemctl enable docker.service
systemctl start docker.service

# Install Docker Compose
curl -L https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Add user to docker group
groupadd docker
usermod -aG docker opc
newgrp docker

# Install git
dnf -y install git

# Setup zsh
dnf -y install zsh
chsh -s $(which zsh) opc
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="spaceship"/' ~/.zshrc
echo 'alias zshconfig="nano ~/.zshrc"' >> ~/.zshrc
echo 'alias ohmyzsh="nano ~/.oh-my-zsh"' >> ~/.zshrc
echo 'alias ra="source ~/.zshrc"' >> ~/.zshrc
sed -i 's/^plugins=.*/plugins=(git docker docker-compose nvm git-lfs)/' ~/.zshrc
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.zshrc

# Install Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | zsh
nvm i --lts

