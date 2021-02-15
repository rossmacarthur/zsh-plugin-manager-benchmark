#!/usr/bin/env bash
#
# Install Docker on a new Ubuntu 20.04 host
# See https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04

set -ex

sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce
