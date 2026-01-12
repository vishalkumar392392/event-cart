#!/bin/bash
set -e

LOG=/var/log/artifactory-install.log
exec > >(tee -a $LOG) 2>&1

echo "===== Update system ====="
dnf update -y

echo "===== Install packages ====="
dnf install -y java-11-amazon-corretto wget tar firewalld shadow-utils

echo "===== Enable and start firewalld ====="
systemctl enable firewalld
systemctl start firewalld

echo "===== Open Artifactory port ====="
firewall-cmd --permanent --add-port=8081/tcp
firewall-cmd --reload

echo "===== Create jfrog user ====="
id jfrog &>/dev/null || useradd --system --create-home --home-dir /opt/jfrog --shell /sbin/nologin jfrog

echo "===== Download Artifactory ====="
cd /opt
ART_VERSION=7.77.5
wget https://releases.jfrog.io/artifactory/bintray-artifactory/org/artifactory/oss/jfrog-artifactory-oss/${ART_VERSION}/jfrog-artifactory-oss-${ART_VERSION}-linux.tar.gz

echo "===== Extract Artifactory ====="
tar -xzf jfrog-artifactory-oss-${ART_VERSION}-linux.tar.gz
mv artifactory-oss-* artifactory

echo "===== Set permissions ====="
chown -R jfrog:jfrog /opt/artifactory

echo "===== Create systemd service ====="
cat <<EOF > /etc/systemd/system/artifactory.service
[Unit]
Description=JFrog Artifactory OSS
After=network.target

[Service]
Type=forking
User=jfrog
Group=jfrog
LimitNOFILE=100000
ExecStart=/opt/artifactory/app/bin/artifactory.sh start
ExecStop=/opt/artifactory/app/bin/artifactory.sh stop
Restart=on-failure
TimeoutSec=300

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable artifactory
systemctl start artifactory

echo "===== Artifactory installation complete ====="
