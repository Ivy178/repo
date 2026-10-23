bash
  
#!/bin/bash

PYTHON_BIN=/usr/bin/python3.12

if ! command -v "${PYTHON_BIN}" >/dev/null 2>&1; then
    PYTHON_BIN=$(command -v python3.12 || true)
fi

if [ -z "${PYTHON_BIN}" ]; then
    echo "[ERROR] python3.12 is not available on this image"
    exit 1
fi

function change_text_color() {
    local text=$1
    local color=$2
    local escape_code="\033[${color}m"
    local reset_code="\033[0m"
    printf "${escape_code}${text}${reset_code}\n"
}

export AIRFLOW_HOME=/opt/airflow

export REGION_NAME=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/region -H "Metadata-Flavor: Google")
export PROJECT_NAME=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/secret-project-name -H "Metadata-Flavor: Google")
export SECRET_PROJECT_NAME=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/secret-project-name -H "Metadata-Flavor: Google")
export SECRET_NAME_NODE_CERT=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/secret-san-node-cert -H "Metadata-Flavor: Google")
export SECRET_NAME_NODE_KEY=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/secret-san-node-key -H "Metadata-Flavor: Google")
export CERT_KEY=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/cert-key -H "Metadata-Flavor: Google")
export SECRET_NAME_RABBITMQ_CRED=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/secret-name-rabbitmq-cred -H "Metadata-Flavor: Google")
export LDAP_SERVER=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/ldap-server -H "Metadata-Flavor: Google")
export LDAP_DOMAIN=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/ldap-ou-name -H "Metadata-Flavor: Google")
export SECRET_NAME_LDAP_CRED=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/secret-name-ldap-cred -H "Metadata-Flavor: Google")
export SECRET_NAME_CELERY_CRED=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/secret-name-celery-cred -H "Metadata-Flavor: Google")
export API_HOST=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/api-host -H "Metadata-Flavor: Google")
export AIRFLOW_API_KEY_ID=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/secret-api-key-id -H "Metadata-Flavor: Google")
export ENVIRONMENT_NAME=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/env -H "Metadata-Flavor: Google")
export BASE_URL=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/base-url -H "Metadata-Flavor: Google")
export WEB_SERVER_HOST=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/web-server-host -H "Metadata-Flavor: Google")
export SQL_INSTANCE=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/sql-instance -H "Metadata-Flavor: Google")
export SQL_USER=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/sql-user -H "Metadata-Flavor: Google")
export SECRET_NAME_KEY=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/secret-name-key -H "Metadata-Flavor: Google")
export LOG_BUCKET=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/log-bucket -H "Metadata-Flavor: Google")
export DAG_FILE_BUCKET=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/dag-file-bucket -H "Metadata-Flavor: Google")
export RABBITMQ_NODE=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/rabbitmq_node -H "Metadata-Flavor: Google")
export PARALLELISM=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/parallelism -H "Metadata-Flavor: Google")
export MAX_ACTIVE_TASKS_PER_DAG=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/max-active-tasks-per-dag -H "Metadata-Flavor: Google") //
export MAX_ACTIVE_RUNS_PER_DAG=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/max-active-runs-per-dag -H "Metadata-Flavor: Google")
export VHOST=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/vhost -H "Metadata-Flavor: Google")

change_text_color "configureSh -- AIRFLOW_DB=${AIRFLOW_DB} -- " 32
change_text_color "configureSh -- BASE_URL=${BASE_URL} -- " 32
change_text_color "configureSh -- WEB_SERVER_HOST=${WEB_SERVER_HOST} -- " 32
change_text_color "configureSh -- LDAP_SERVER=${LDAP_SERVER} -- " 32
change_text_color "configureSh -- LDAP_OU_NAME=${LDAP_OU_NAME} -- " 32
change_text_color "configureSh -- PROJECT_NAME=${PROJECT_NAME} -- " 32
change_text_color "configureSh -- SQL_INSTANCE=${SQL_INSTANCE} -- " 32
change_text_color "configureSh -- SQL_USER=${SQL_USER} -- " 32
change_text_color "configureSh -- CERT_KEY=${CERT_KEY} -- " 33
change_text_color "configureSh -- CERT_CRT=${CERT_CRT} -- " 33
change_text_color "configureSh -- SECRET_NAME_KEY=${SECRET_NAME_KEY} -- " 32
change_text_color "configureSh -- SECRET_NAME_CERT=${SECRET_NAME_CERT} -- " 32
change_text_color "configureSh -- SECRET_NAME_LDAP_CRED=${SECRET_NAME_LDAP_CRED} -- " 32
change_text_color "configureSh -- SECRET_PROJECT_NAME=${SECRET_PROJECT_NAME} -- " 32
change_text_color "configureSh -- LOG_BUCKET=${LOG_BUCKET} -- " 32
change_text_color "configureSh -- DAG_FILE_BUCKET=${DAG_FILE_BUCKET} -- " 32
change_text_color "configureSh -- RABBITMQ_NODE=${RABBITMQ_NODE} -- " 33
change_text_color "configureSh -- SECRET_NAME_RABBITMQ_CRED=${SECRET_NAME_RABBITMQ_CRED} -- " 33
change_text_color "configureSh -- SECRET_NAME_CELERY_CRED=${SECRET_NAME_CELERY_CRED} -- " 33
change_text_color "configureSh -- SECRET_NAME_NODE_CERT=${SECRET_NAME_NODE_CERT} -- " 33
change_text_color "configureSh -- SECRET_NAME_NODE_KEY=${SECRET_NAME_NODE_KEY} -- " 33
change_text_color "configureSh -- SERVER_NAME=${SERVER_NAME} -- " 32
change_text_color "configureSh -- API_HOST=${API_HOST} -- " 32
change_text_color "configureSh -- SECRET_API_KEY_ID=${SECRET_API_KEY_ID} -- " 32

export API_KEY_ID=$(gcloud secrets versions access latest --secret="${SECRET_API_KEY_ID}" --project="${SECRET_PROJECT_NAME}")
export SECRET_KEY="jU6yjsPhSmYwrqHKvrcB0e=="

envsubst < ${AIRFLOW_HOME}/airflow.tmpl > ${AIRFLOW_HOME}/airflow.cfg
envsubst < ${AIRFLOW_HOME}/airflow.tmpl > /usr/local/sbin/airflow.cfg
envsubst < ${AIRFLOW_HOME}/webserver_config_ldap.tmpl > ${AIRFLOW_HOME}/webserver_config.tmpl
envsubst < /etc/nginx/nginx.tmpl > /etc/nginx/nginx.conf

sed -i "s|@host|@host;g;s|@remote_addr|@remote_addr;g;s|@proxy_add_x_forwarded_for|@proxy_add_x_forwarded_for;g;s|@scheme|@scheme;g;s|@|$|g" /etc/nginx/nginx.conf
cat /etc/nginx/nginx.conf
sed -i "s|@USER|@USER;g;s|@PASSWORD|@PASSWORD;g;s|@|$|g" /opt/airflow/webserver_config.tmpl
cat ${AIRFLOW_HOME}/webserver_config.tmpl
mkdir -p /opt/airflow
cat <<EOF > /usr/local/sbin/cloud-sql-proxy.sh
#!/bin/bash
/opt/cloud-sql-proxy/cloud_sql_proxy -instances=${SQL_INSTANCE} -enable_iam_login -ip_address_types=PRIVATE -verbose=false 2>&1 >> /var/log/sql_proxy.log
EOF
change_text_color "Getting LDAP Bind User Name and Password, SSL Certs for airflow and rabbitmq" 32

cat <<EOF > /usr/local/sbin/airflow-ldap-certs.sh
#!/bin/bash
gcloud secrets versions access latest --secret="${SECRET_NAME_LDAP_CRED}" --project="${SECRET_PROJECT_NAME}" > /opt/airflow/airflow_config.secrets
dos2unix /opt/airflow/airflow_config.secrets
eval "\$(cat /opt/airflow/airflow_config.secrets)"
envsubst < /opt/airflow/webserver_config.tmpl > /opt/airflow/webserver_config.py
rm /opt/airflow/airflow_config.secrets
cat /opt/airflow/webserver_config.py
#ssl certificates
gcloud secrets versions access latest --secret="${SECRET_NAME_KEY}" --project="${SECRET_PROJECT_NAME}" > ${CERT_KEY}
gcloud secrets versions access latest --secret="${SECRET_NAME_CERT}" --project="${SECRET_PROJECT_NAME}" > ${CERT_CRT}
gcloud secrets versions access latest --secret="${SECRET_NAME_NODE_CERT}" --project="${SECRET_PROJECT_NAME}" > /opt/airflow/cert/rabbitmq-node.crt
gcloud secrets versions access latest --secret="${SECRET_NAME_NODE_KEY}" --project="${SECRET_PROJECT_NAME}" > /opt/airflow/cert/rabbitmq-node.key
unset PASSWORD
echo "Certificate -- File list"
ls -l /opt/airflow/cert/*.key
ls -l /opt/airflow/cert/*.crt
rm -f /opt/airflow/airflow_config.secrets
EOF

cat <<EOF > /usr/local/sbin/gcs_fuse.sh
#!/bin/bash
/usr/bin/gcsfuse --implicit-dirs ${DAG_FILE_BUCKET} /opt/airflow/${VHOST}_airflow 2>&1 >> /var/log/gcs_fuse.log
EOF

cat <<EOF > /usr/local/sbin/rabbitmq.sh
#!/bin/bash
chmod +x /usr/local/sbin/rabbitmq-cluster.sh
chmod +x /usr/local/sbin/airflow.cfg
chmod +x /usr/local/sbin/logging.sh
sed -i "s|#||g" /usr/local/sbin/rabbitmq-cluster.sh
sed -i "s|#||g" /usr/local/sbin/service_log.sh
sed -i "s|api_host|${API_HOST}|g;s|api_key_id|${API_KEY_ID}|g" /usr/local/sbin/monitoring.py
sed -i "s|#||g" /usr/local/sbin/logging.sh

/usr/local/sbin/logging.sh

/usr/local/sbin/rabbitmq-cluster.sh
EOF

# Configuration for Airflow Logging using fluentd
cat <<EOF > /usr/local/sbin/logging.sh
#!/bin/bash
curl --header "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/name > current_node.log
current_node#\$(cat ./current_node.log)
sed -i "s|server_name#|${current_node}|g" /usr/local/sbin/logging.conf
EOF

sed -i "s|server_name|#${current_node}|g" /usr/local/sbin/logging.conf  //
cp /usr/local/sbin/logging.conf /etc/google-fluentd/config.d/
systemctl restart google-fluentd
systemctl status google-fluentd -l
EOF

# Configure RabbitMQ-Cluster
change_text_color "Configure RabbitMQ-Cluster" 32
cat <<EOF > /usr/local/sbin/rabbitmq-cluster.sh
#!/bin/bash
gcloud secrets versions access latest --secret="${SECRET_NAME_CELERY_CRED}" --project="${SECRET_PROJECT_NAME}" > /usr/local/sbin/cred.log
celery_user=#$(head -1 /usr/local/sbin/cred.log | tail -1 | cut -d ':' -f 2)
celery_pass=#$(head -2 /usr/local/sbin/cred.log | tail -1 | cut -d ':' -f 2)

gcloud secrets versions access latest --secret="${SECRET_NAME_RABBITMQ_CRED}" --project="${SECRET_PROJECT_NAME}" > /usr/local/sbin/user.log
rabbitmq_user=#$(head -1 /usr/local/sbin/user.log | tail -1 | cut -d ':' -f 2)
rabbitmq_pass=#$(head -2 /usr/local/sbin/user.log | tail -1 | cut -d ':' -f 2)

echo "amqps://#${rabbitmq_user}:#${rabbitmq_pass}@${RABBITMQ_NODE}:5671/${VHOST}_host;" >> broker.log
tr -d '[:space:]' < ./broker.log | sed 's;#//' > broker_url.log
broker=#$(cat ./broker_url.log)
rm -rf /opt/airflow/airflow.cfg

sed "s|#broker_url|#${broker}|g;s|#User|#${celery_user}|g;s|#Password|#${celery_pass}|g" /usr/local/sbin/airflow.cfg > /opt/airflow/airflow.cfg

systemctl restart airflow-api-server.service
systemctl status airflow-api-server.service
systemctl restart airflow-scheduler.service
systemctl status airflow-scheduler.service
systemctl restart celery-worker.service
systemctl status celery-worker.service
systemctl restart flower.service
systemctl status flower.service

rm -rf *.log
rm -rf /usr/local/sbin/*.log
EOF

# removed Log file in every 8 hour
cat <<EOF > /usr/local/sbin/service_log.sh
#!/bin/bash
filename='/opt/airflow/service.log'
# Check the file is exists or not
if [ -f #filename ]; then
    rm -rf #filename
    echo "#filename is removed"
fi
EOF

# removed Log file more than 7days
cat <<EOF > /usr/local/sbin/remove_log.sh
#!/bin/bash
echo "\$(date '+%F %T') [remove_log] triggered" > /dev/console
find /opt/airflow/logs/scheduler/ -type d -mtime +6 -exec sudo rm -rf {} \;
EOF

cat << EOF > /etc/sysconfig/airflow
AIRFLOW_HOME=/opt/airflow
AIRFLOW_CONFIG=/opt/airflow/airflow.cfg
PYTHONPATH=/opt/airflow/config:/opt/airflow
AIRFLOW_VAR_API_HOST=$API_HOST
AIRFLOW_VAR_API_KEY_ID=$API_KEY_ID
AIRFLOW_VAR_ENV_NAME=$ENVIRONMENT_NAME
AIRFLOW_VAR_PROJECT_ID=$PROJECT_NAME
AIRFLOW_VAR_SQL_USER=$SQL_USER
AIRFLOW_VAR_PROXY_ADDRESS=127.0.0.1
AIRFLOW_VAR_SQL_INSTANCE_PORT=5432
AIRFLOW_VAR_GCP_REGION=$REGION
AIRFLOW_VAR_KMS_PATH=projects/hsbc-6320774-kms-\$(echo "\$PROJECT_NAME" | awk -F '-' '{print \$NF}')/locations/\$REGION/keyRings/\$PROJECT_NAME
AIRFLOW_VHOST=$VHOST
EOF

# Set cronjob to run every 8 hour
chmod +x /usr/local/sbin/service_log.sh
(crontab -l 2>/dev/null; echo "0 */8 * * * /bin/bash /usr/local/sbin/service_log.sh") | crontab -

# Set cronjob to run every 5 min
chmod +x /usr/local/sbin/monitoring.py
(crontab -l 2>/dev/null; echo "*/5 * * * * ${PYTHON_BIN} /usr/local/sbin/monitoring.py") | crontab -

# Set cronjob to run 4am every day
chmod +x /usr/local/sbin/remove_log.sh
(crontab -l 2>/dev/null; echo "0 4 * * * /bin/bash /usr/local/sbin/remove_log.sh") | crontab -