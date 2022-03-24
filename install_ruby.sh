#!/bin/sh
sudo apt update && sudo apt upgrade -y
sudo fw disable
sudo systemctl disable apparmor
sudo apt install -y ruby-full ruby-bundler build-essential
ruby -v
bundler -v
