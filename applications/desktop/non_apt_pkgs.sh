#!/bin/bash

echo "Installing Brave"
curl -fsS https://dl.brave.com/install.sh | sh

echo "Installing Upscayl"
curl -fsS -o /tmp/upscayl-2.15.0-linux.deb https://github.com/upscayl/upscayl/releases/download/v2.15.0/upscayl-2.15.0-linux.deb
sudo dpkg -i /tmp/upscayl-2.15.0-linux.deb

sudo apt install -f
