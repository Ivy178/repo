bash
  
#!/bin/bash
set -euo pipefail

declare data=()

declare RABBITMQ_CLUSTER_HOSTS="$1"
declare REGION="$2"
declare SECRET_SAN_NODE_CERT="$3"
declare SECRET_SAN_NODE_KEY="$4"
declare SECRET_PROJECT_NAME="$5"

current_node=$(curl --header "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/name)

echo "[INFO] RabbitMQ Certificates" > /dev/ttyS0

gcloud secrets versions access latest --secret="${SECRET_SAN_NODE_CERT}" --project="${SECRET_PROJECT_NAME}" > /etc/pki/tls/rabbitmq-node.crt
gcloud secrets versions access latest --secret="${SECRET_SAN_NODE_KEY}" --project="${SECRET_PROJECT_NAME}" > /etc/pki/tls/rabbitmq-node.key
chgrp rabbitmq /etc/pki/tls/rabbitmq-node.crt /etc/pki/tls/rabbitmq-node.key
chmod 640 /etc/pki/tls/rabbitmq-node.crt /etc/pki/tls/rabbitmq-node.key

echo "[INFO] RabbitMQ Certificates for ${current_node} $(ls /etc/pki/tls/rabbitmq*)" > /dev/ttyS0

if [[ -z "${RABBITMQ_CLUSTER_HOSTS}" ]]; then
    echo "[ERROR] RABBITMQ_CLUSTER_HOSTS is empty; cannot generate cluster_formation config" > /dev/ttyS0
    exit 1
fi

echo "[INFO] Building cluster config from RABBITMQ_CLUSTER_HOSTS=${RABBITMQ_CLUSTER_HOSTS}" > /dev/ttyS0

n=1
IFS=':' read -ra host_array <<< "$RABBITMQ_CLUSTER_HOSTS"
for host in "${host_array[@]}"; do
    host="$(echo "$host" | xargs)"
    [[ -z "$host" ]] && continue
    data+=("cluster_formation.classic_config.nodes.${n} = rabbit@${host}")
    n=$((n + 1))
done

if [[ ${#data[@]} -eq 0 ]]; then
    echo "[ERROR] No valid cluster hosts parsed from RABBITMQ_CLUSTER_HOSTS='${RABBITMQ_CLUSTER_HOSTS}'" > /dev/ttyS0
    exit 1
fi

(IFS=$'\n'; echo "${data[*]}") > config.log

cat /etc/rabbitmq.conf | sed "s/@cluster_formation@/$(cat config.log)/e" > /etc/rabbitmq/rabbitmq.conf

echo -e "[CLUSTER FORMATION]\n $(cat /etc/rabbitmq/rabbitmq.conf | grep cluster_formation.classic_config.nodes)" > /dev/ttyS0