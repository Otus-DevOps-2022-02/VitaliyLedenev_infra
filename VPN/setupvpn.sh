#!/bin/bash
tee /etc/apt/sources.list.d/pritunl.list << EOF
deb http://repo.pritunl.com/stable/apt focal main
EOF

# Import signing key from keyserver
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 7568D9BB55FF9E5287D586017AE645C0CF8E292A
# Alternative import from download if keyserver offline
curl https://raw.githubusercontent.com/pritunl/pgp/master/pritunl_repo_pub.asc | sudo apt-key add -

tee /etc/apt/sources.list.d/mongodb-org-5.0.list << EOF
deb https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse
EOF

curl https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -

sudo apt update

# WireGuard server support
apt -y install wireguard wireguard-tools
ufw disable
systemctl disable apparmor
apt -y install pritunl mongodb-org
systemctl enable mongod pritunl
systemctl start mongod pritunl
echo "wait plz, make setup-key for pritunl"
pritunl setup-key
echo "go to https://ext_ip/setup and enter seup key"
