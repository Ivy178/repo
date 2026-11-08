#!/bin/bash

declare rabbitmq_user
declare rabbitmq_pass
declare SECRET_NAME_RABBITMQ_CRED="$1"
declare SECRET_PROJECT_NAME="$2"
declare SECRET_NAME_CELERY_CRED="$3"
declare BASE_VHOST="$4"
declare VHOST="${BASE_VHOST}_host"

echo "In-use vhost: ${VHOST}"

if [[ "${current_node}" == "rabbitmq-server-1"* ]]; then
    gcloud secrets versions access latest --secret="${SECRET_NAME_RABBITMQ_CRED}" --project="${SECRET_PROJECT_NAME}" > /usr/local/sbin/cred.log
    rabbitmq_user=$(head -1 /usr/local/sbin/cred.log | tail -1 | cut -d ':' -f 2)
    rabbitmq_pass=$(head -2 /usr/local/sbin/cred.log | tail -1 | cut -d ':' -f 2)
else
    sleep 30
    gcloud secrets versions access latest --secret="${SECRET_NAME_RABBITMQ_CRED}" --project="${SECRET_PROJECT_NAME}" > /usr/local/sbin/cred.log
    rabbitmq_user=$(head -1 /usr/local/sbin/cred.log | tail -1 | cut -d ':' -f 2)
    rabbitmq_pass=$(head -2 /usr/local/sbin/cred.log | tail -1 | cut -d ':' -f 2)
fi

sleep 60

sudo rabbitmqctl add_user "$rabbitmq_user" "$rabbitmq_pass" || true
sudo rabbitmqctl add_vhost "$VHOST" || true
sudo rabbitmqctl set_user_tags "$rabbitmq_user" administrator || true
sudo rabbitmqctl set_permissions -p "$VHOST" "$rabbitmq_user" ".*" ".*" ".*"