#!/usr/bin/env bash
set -euo pipefail
mkdir -p /home/azure-user
touch /home/azure-user/.bash_profile

export DEBIAN_FRONTEND=noninteractive

echo "# lazygit..."
sudo add-apt-repository --yes ppa:lazygit-team/release
sudo apt-get update
sudo apt-get install -y lazygit

# install git and python pyenv dependencies
echo "installing git, other dependencies"
sudo apt install -y make git zip unzip wget jq curl

# install docker
echo "installing Docker CE"
sudo apt-get install -y\
     ca-certificates \
     curl \
     gnupg \
     lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
   "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo systemctl enable docker
sudo usermod -aG docker azure-user
sudo newgrp docker
sudo systemctl start docker.service
# enable and start docker daemon
echo "service enable and start docker"
sudo systemctl enable --now docker

# compose
echo "installing docker-compose"
sudo curl -SL https://github.com/docker/compose/releases/download/v2.4.1/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

####################################################
# install node
echo "installing node"
sudo apt install nodejs -y
####################################################

echo '# azure cli'
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash


####################################################
# install golang
echo "installing go"
sudo apt install -y golang-go
####################################################

cat<<EOF >> /home/azure-user/.bash_profile
export GOPATH='/home/azure-user/go'
export GOROOT='/usr/local/go'
export PATH="$PATH:/usr/local/bin:$GOROOT/bin:$GOPATH/bin"
export GO111MODULE="on"
export GOSUMDB=off
EOF
####################################################
### Python
#----------------------------------------
# installing python using pyenv as yum breaks when using yum and update-alternatives
echo "installing Python 3.9"
# install dependencies
sudo apt install -y make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
    libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl git

# ref: https://www.singlestoneconsulting.com/blog/setting-up-your-python-environment/
sudo runuser -l azure-user -c "curl https://pyenv.run | bash"
sudo runuser -l azure-user -c "/home/azure-user/.pyenv/bin/pyenv install 3.9.12"
sudo runuser -l azure-user -c "/home/azure-user/.pyenv/bin/pyenv global 3.9.12"

cat<<EOF >> /home/azure-user/.bash_profile
export PATH="\$HOME/.pyenv/bin:$PATH"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"
EOF

sudo runuser -l azure-user -c echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> /home/azure-user/.bash_profile
sudo runuser -l azure-user -c echo 'eval "$(pyenv init -)"' >> /home/azure-user/.bash_profile
sudo runuser -l azure-user -c echo 'eval "$(pyenv virtualenv-init -)"' >> /home/azure-user/.bash_profile
####################################################
### Java
# installing JDK
echo "installing JDK 11"
# NOTE - cant use amazon-linux-extras as they default to openjdk-17 or yum - as it installs older version fo maven - HAVE TO USE SDKMAN
echo "installing sdkman and java"

sudo runuser  -l azure-user -c 'curl -s "https://get.sdkman.io" | bash'
sudo runuser  -l azure-user -c 'source /home/azure-user/.sdkman/bin/sdkman-init.sh && sdk install java 11.0.11.hs-adpt && sdk install maven'
sudo runuser  -l azure-user -c ''
cat <<EOF  >> /home/azure-user/.bash_profile
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="\$HOME/.sdkman"
[[ -s "\$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "\$HOME/.sdkman/bin/sdkman-init.sh"
EOF

# install maven
sudo apt install maven

####################################################
# install azure cloud CLI
echo "installing Azure CLI"
sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg
curl -sL https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor |
    sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |
    sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-get update -y
sudo apt-get install -y azure-cli

## install azure functions core tool
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'
sudo apt-get update
sudo apt-get install azure-functions-core-tools-4

####################################################

echo "# dapr..."
wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash

dapr init

echo "# complete!"
