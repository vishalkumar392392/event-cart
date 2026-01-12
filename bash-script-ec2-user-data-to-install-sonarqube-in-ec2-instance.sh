#!/bin/bash
set -eux

SONAR_VERSION="9.9.3.79811"
SONAR_USER="sonar"
SONAR_DB="sonarqube"
SONAR_DB_USER="sonar"
SONAR_DB_PASS="sonar123"

# Update OS
dnf update -y

# Install Java 17
dnf install -y java-17-amazon-corretto unzip wget

# Install PostgreSQL 15
dnf install -y postgresql15 postgresql15-server
/usr/bin/postgresql-setup --initdb
systemctl enable postgresql
systemctl start postgresql

# Configure PostgreSQL auth (md5)
sed -i 's/ident/md5/g' /var/lib/pgsql/data/pg_hba.conf
systemctl restart postgresql

# Create database and user
sudo -i -u postgres psql <<EOF
CREATE DATABASE ${SONAR_DB};
CREATE USER ${SONAR_DB_USER} WITH ENCRYPTED PASSWORD '${SONAR_DB_PASS}';
GRANT ALL PRIVILEGES ON DATABASE ${SONAR_DB} TO ${SONAR_DB_USER};
EOF

# Fix PostgreSQL schema permissions
sudo -i -u postgres psql -d ${SONAR_DB} <<EOF
ALTER SCHEMA public OWNER TO ${SONAR_DB_USER};
GRANT ALL PRIVILEGES ON SCHEMA public TO ${SONAR_DB_USER};
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${SONAR_DB_USER};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${SONAR_DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${SONAR_DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${SONAR_DB_USER};
EOF

# Kernel limits for Elasticsearch
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

# User limits
cat <<EOF >> /etc/security/limits.conf
${SONAR_USER}   -   nofile   65536
${SONAR_USER}   -   nproc    4096
EOF

# Create sonar user
id ${SONAR_USER} &>/dev/null || useradd ${SONAR_USER}

# Install SonarQube
cd /opt
wget -q https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONAR_VERSION}.zip
unzip -q sonarqube-${SONAR_VERSION}.zip
mv sonarqube-${SONAR_VERSION} sonarqube
chown -R ${SONAR_USER}:${SONAR_USER} /opt/sonarqube

# Configure SonarQube DB
cat <<EOF >> /opt/sonarqube/conf/sonar.properties
sonar.jdbc.username=${SONAR_DB_USER}
sonar.jdbc.password=${SONAR_DB_PASS}
sonar.jdbc.url=jdbc:postgresql://localhost:5432/${SONAR_DB}
EOF

# systemd service
cat <<EOF > /etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube service
After=network.target

[Service]
Type=forking
User=${SONAR_USER}
Group=${SONAR_USER}
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
LimitNOFILE=65536
LimitNPROC=4096
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start SonarQube
systemctl daemon-reload
systemctl enable sonarqube
systemctl start sonarqube