#!/bin/bash
set -e

############################
# VARIABLES
############################
KAFKA_VERSION="3.6.0"
SCALA_VERSION="2.13"
KAFKA_HOME="/opt/kafka"
DATA_DIR="/data/kafka"
KAFKA_USER="ec2-user"

############################
# GET EC2 PRIVATE IP (IMDSv2)
############################
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

NODE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)

############################
# GLOBAL KAFKA ENV VARIABLES
# (Persist across reboot & login)
############################
cat <<EOF > /etc/profile.d/kafka.sh
export KAFKA_HOME=/opt/kafka
export BOOTSTRAP_SERVER=${NODE_IP}:9092
export PATH=\$PATH:/opt/kafka/bin
EOF

chmod +x /etc/profile.d/kafka.sh

############################
# INSTALL DEPENDENCIES
############################
yum update -y
yum install -y java-17-amazon-corretto wget

############################
# INSTALL KAFKA (IDEMPOTENT)
############################
if [ ! -d "/opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}" ]; then
  cd /opt
  wget https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz
  tar -xzf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz
  ln -s kafka_${SCALA_VERSION}-${KAFKA_VERSION} kafka
fi

chown -R ${KAFKA_USER}:${KAFKA_USER} /opt/kafka*

############################
# DATA DIRECTORIES
############################
mkdir -p ${DATA_DIR}/broker{1,2,3}
chown -R ${KAFKA_USER}:${KAFKA_USER} /data

############################
# CLUSTER ID (PERSISTENT)
############################
if [ ! -f "${DATA_DIR}/.cluster_id" ]; then
  CLUSTER_ID=$(${KAFKA_HOME}/bin/kafka-storage.sh random-uuid)
  echo $CLUSTER_ID > ${DATA_DIR}/.cluster_id
else
  CLUSTER_ID=$(cat ${DATA_DIR}/.cluster_id)
fi

############################
# KAFKA CONFIG FILES
############################
for i in 1 2 3; do
  BROKER_PORT=$((9091 + i))
  CTRL_PORT=$((19090 + i))

  cat <<EOF > ${KAFKA_HOME}/config/kraft/broker${i}.properties
process.roles=broker,controller
node.id=${i}

controller.quorum.voters=1@${NODE_IP}:19091,2@${NODE_IP}:19092,3@${NODE_IP}:19093

listeners=PLAINTEXT://0.0.0.0:${BROKER_PORT},CONTROLLER://0.0.0.0:${CTRL_PORT}
advertised.listeners=PLAINTEXT://${NODE_IP}:${BROKER_PORT}

listener.security.protocol.map=PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT
inter.broker.listener.name=PLAINTEXT
controller.listener.names=CONTROLLER

log.dirs=${DATA_DIR}/broker${i}

num.partitions=3
offsets.topic.replication.factor=3
transaction.state.log.replication.factor=3
transaction.state.log.min.isr=2
EOF
done

############################
# FORMAT STORAGE (RUN ONCE)
############################
if [ ! -f "${DATA_DIR}/.formatted" ]; then
  for i in 1 2 3; do
    ${KAFKA_HOME}/bin/kafka-storage.sh format \
      -t $CLUSTER_ID \
      -c ${KAFKA_HOME}/config/kraft/broker${i}.properties
  done
  touch ${DATA_DIR}/.formatted
fi

############################
# SYSTEMD SERVICES
############################
for i in 1 2 3; do
cat <<EOF > /etc/systemd/system/kafka-broker${i}.service
[Unit]
Description=Apache Kafka Broker ${i}
After=network.target

[Service]
Type=simple
User=${KAFKA_USER}
ExecStart=${KAFKA_HOME}/bin/kafka-server-start.sh ${KAFKA_HOME}/config/kraft/broker${i}.properties
ExecStop=${KAFKA_HOME}/bin/kafka-server-stop.sh
Restart=always
RestartSec=10
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOF
done

############################
# ENABLE & START SERVICES
############################
systemctl daemon-reexec
systemctl daemon-reload

for i in 1 2 3; do
  systemctl enable kafka-broker${i}
  systemctl start kafka-broker${i}
done

echo "✅ Kafka 3.6.0 KRaft cluster started with systemd + env vars"
