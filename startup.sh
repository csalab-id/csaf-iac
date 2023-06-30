#!/bin/bash

apt update
apt -y install ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
apt update
DEBIAN_FRONTEND=noninteractive apt -yq install git docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose
yes | DEBIAN_FRONTEND=noninteractive apt -yq upgrade
apt -y autoremove
apt clean all
cd /root/
git clone https://github.com/csalab-id/csaf-docker
cd csaf-docker
docker-compose pull
docker-compose build
docker-compose -f generate-indexer-certs.yml run --rm generator
docker-compose up -d
