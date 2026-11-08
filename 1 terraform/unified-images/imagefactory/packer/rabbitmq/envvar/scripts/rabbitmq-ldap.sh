#!/bin/bash

SECRET_NAME_LDAP_CRED="$1"
SECRET_PROJECT_NAME="$2"

if [ -z "$SECRET_NAME_LDAP_CRED" ] || [ -z "$SECRET_PROJECT_NAME" ]; then
    echo "Usage: $0 <secret-name-ldap-cred> <secret-project-name>" >&2
    exit 1
fi

gcloud secrets versions access latest --secret="${SECRET_NAME_LDAP_CRED}" --project="${SECRET_PROJECT_NAME}" > /etc/rabbitmq/rabbitmq_config.secrets
dos2unix /etc/rabbitmq/rabbitmq_config.secrets
eval "$(cat /etc/rabbitmq/rabbitmq_config.secrets)"
envsubst < /etc/rabbitmq/advanced.tmpl > /etc/rabbitmq/advanced.config
cat /etc/rabbitmq/rabbitmq_config.secrets
cat /etc/rabbitmq/advanced.config
unset PASSWORD
rm -f /etc/rabbitmq/rabbitmq_config.secrets