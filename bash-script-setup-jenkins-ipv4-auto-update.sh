#!/bin/bash
set -e

###############################################################################
# Script Name : setup-jenkins-ipv4-auto-update.sh
# Purpose     : One-time setup to auto-update Jenkins public IPv4 on every reboot
# Requirement : Jenkins must already be installed and started once
###############################################################################

LOG_FILE="/var/log/jenkins-ip-update.log"
exec > >(tee -a $LOG_FILE) 2>&1

echo "===== Jenkins IPv4 Auto-Update Setup Started ====="

# ---------------------------------------------------------------------------
# Validate Jenkins installation
# ---------------------------------------------------------------------------
JENKINS_SERVICE="jenkins"
JENKINS_LOCATION_FILE="/var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml"

if ! systemctl list-unit-files | grep -q "^${JENKINS_SERVICE}.service"; then
  echo "ERROR: Jenkins service not found. Install Jenkins first."
  exit 1
fi

if [ ! -f "$JENKINS_LOCATION_FILE" ]; then
  echo "ERROR: Jenkins location config not found."
  echo "Start Jenkins once before running this script."
  exit 1
fi

echo "Jenkins installation verified."

# ---------------------------------------------------------------------------
# Create the update script (runs on every reboot)
# ---------------------------------------------------------------------------
UPDATE_SCRIPT="/usr/local/bin/update-jenkins-url.sh"

echo "Creating Jenkins URL update script..."

cat << 'EOF' > $UPDATE_SCRIPT
#!/bin/bash
set -e

PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)
JENKINS_LOCATION_FILE="/var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml"

if [ -z "$PUBLIC_IP" ]; then
  echo "ERROR: Unable to fetch public IPv4"
  exit 1
fi

cp ${JENKINS_LOCATION_FILE} ${JENKINS_LOCATION_FILE}.bak

sed -i "s|<jenkinsUrl>.*</jenkinsUrl>|<jenkinsUrl>http://${PUBLIC_IP}:8080/</jenkinsUrl>|" \
${JENKINS_LOCATION_FILE}

systemctl restart jenkins

echo "Jenkins URL updated to http://${PUBLIC_IP}:8080/"
EOF

chmod +x $UPDATE_SCRIPT

# ---------------------------------------------------------------------------
# Create systemd service (runs on EVERY boot)
# ---------------------------------------------------------------------------
SERVICE_FILE="/etc/systemd/system/jenkins-url-update.service"

echo "Creating systemd service..."

cat << 'EOF' > $SERVICE_FILE
[Unit]
Description=Update Jenkins URL with current Public IPv4
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/update-jenkins-url.sh

[Install]
WantedBy=multi-user.target
EOF

# ---------------------------------------------------------------------------
# Enable service (persistent across reboots)
# ---------------------------------------------------------------------------
echo "Enabling systemd service..."
systemctl daemon-reload
systemctl enable jenkins-url-update

# ---------------------------------------------------------------------------
# Run once immediately
# ---------------------------------------------------------------------------
echo "Running update once now..."
systemctl start jenkins-url-update

echo "===== Jenkins IPv4 Auto-Update Setup Completed ====="