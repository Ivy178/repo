#!/bin/bash

get_meta() {
    local key="$1"
    # -f: fail on non-2xx, -sS: silent but show errors
    curl -fsS "http://metadata.google.internal/computeMetadata/v1/instance/attributes/${key}" \
        -H "Metadata-Flavor: Google"
}

get_meta_optional() {
    local key="$1"
    curl -fsS "http://metadata.google.internal/computeMetadata/v1/instance/attributes/${key}" \
        -H "Metadata-Flavor: Google" 2>/dev/null || true
}

get_zone() {
    # returns e.g. asia-east2-b
    curl -fsS -H "Metadata-Flavor: Google" \
    "http://metadata.google.internal/computeMetadata/v1/instance/zone" | awk -F/ '{print $NF}'
}

build_hosts_from_mig() {
    local mig_name="$1"
    [[ -z "$mig_name" ]] && return 1

    if [[ -z "${REGION:-}" || -z "${SECRET_PROJECT_NAME:-}" ]]; then
        echo "[ERROR] REGION or SECRET_PROJECT_NAME is not set; cannot discover nodes from MIG" >&2
        return 1
    fi

    local instance_rows
    local cmd_output
    local cmd_rc

    echo "[INFO] Discovering RabbitMQ MIG hosts: project='${SECRET_PROJECT_NAME}', region='${REGION}', mig='${mig_name}'" >&2

    cmd_output="$(gcloud compute instance-groups managed list-instances "$mig_name" \
    --project="$SECRET_PROJECT_NAME" \
    --region="$REGION" \
    --format="csv[no-heading](name,ZONE)" \
    --quiet 2>&1)"
    cmd_rc=$?

    echo "[INFO] gcloud managed list-instances completed: project='${SECRET_PROJECT_NAME}', region='${REGION}', mig='${mig_name}', rc=$cmd_rc" >&2

    if [[ $cmd_rc -ne 0 ]]; then
        echo "[ERROR] gcloud list-instances failed for MIG '$mig_name' in project '$SECRET_PROJECT_NAME' region '$REGION' (rc=$cmd_rc)" >&2
        [[ -n "$cmd_output" ]] && echo "[ERROR] gcloud output: $cmd_output" >&2
        return 1
    fi

    instance_rows="$cmd_output"

    if [[ -z "$instance_rows" ]]; then
        echo "[WARN] No instances returned from MIG '$mig_name' in region '$REGION'" >&2
        return 1
    fi

    local discovered=()
    local row name zone fqdn
    while IFS= read -r row; do
        [[ -z "$row" ]] && continue

        name="$(echo "$row" | awk -F, '{print $1}')"
        zone="$(echo "$row" | awk -F, '{print $2}')"

        # Normalize CSV fields from "name,ZONE" output.
        # Example: "rabbitmq-dds-sit-s99m,asia-east2-a" ->
        # name="rabbitmq-dds-sit-s99m", zone="asia-east2-a"
        # If ZONE is returned as a full path like /zones/asia-east2-a/,
        # keep only the last segment so the FQDN becomes:
        # rabbitmq-dds-sit-s99m.asia-east2-a.c.$SECRET_PROJECT_NAME.internal
        name="$(echo "$name" | xargs)"
        zone="$(echo "$zone" | xargs)"
        zone="$(echo "$zone" | awk -F/ '{print $NF}')"

        if [[ -z "$name" || -z "$zone" ]]; then
            echo "[WARN] Skipping MIG row because name/zone could not be parsed: $row" >&2
            continue
        fi

        echo "[INFO] MIG instance discovered: name='${name}', zone='${zone}'" >&2
        fqdn="${name}.${zone}.c.${SECRET_PROJECT_NAME}.internal"
        discovered+=("$fqdn")
    done <<< "$instance_rows"

    if [[ ${#discovered[@]} -eq 0 ]]; then
        echo "[ERROR] No parsable RabbitMQ instances found in MIG '$mig_name'. Raw gcloud output: $instance_rows" >&2
        return 1
    fi

    local out
    out="$(IFS=; echo "${discovered[*]}")"
    echo "$out"
}

# Zone is still useful for logging, but not used for peer FQDN construction.
export ZONE="$(get_zone)"

export SECRET_PROJECT_NAME="$(get_meta secret-project-name)"
export SECRET_SAN_NODE_CERT="$(get_meta secret-san-node-cert)"
export SECRET_SAN_NODE_KEY="$(get_meta secret-san-node-key)"

# Fetch region early: MIG discovery needs it.
export REGION="$(get_meta region)"

# Metadata-provided values for Cluster discovery.
export RABBITMQ_MIG_NAME_RAW="$(get_meta_optional rabbitmq-mig-name)"
if [[ -z "$RABBITMQ_MIG_NAME_RAW" ]]; then
    echo "[ERROR] Missing required instance metadata: rabbitmq-mig-name" >&2
    exit 1
fi

export RABBITMQ_CLUSTER_HOSTS="$(build_hosts_from_mig "$RABBITMQ_MIG_NAME_RAW")"

if [[ -z "${RABBITMQ_CLUSTER_HOSTS:-}" ]]; then
    echo "[ERROR] No RabbitMQ cluster hosts discovered from rabbitmq-mig-name='${RABBITMQ_MIG_NAME_RAW}'." >&2
    exit 1
fi

export SECRET_NAME_RABBITMQ_CRED="$(get_meta secret-name-rabbitmq-cred)"
export LDAP_SERVER="$(get_meta ldap-server)"
export SECRET_NAME_LDAP_CRED="$(get_meta secret-name-ldap-cred)"
export SECRET_NAME_CELERY_CRED="$(get_meta secret-name-celery-cred)"
export API_HOST="$(get_meta api-host)"
export SECRET_API_KEY_ID="$(get_meta secret-api-key-id)"
export VHOST="$(get_meta airflow-vhost)"

echo "configureSh -- -- ZONE(this vm)=${ZONE} =-"
echo "configureSh -- -- SECRET_SAN_NODE_CERT=${SECRET_SAN_NODE_CERT} =-"
echo "configureSh -- -- SECRET_SAN_NODE_KEY=${SECRET_SAN_NODE_KEY} =-"
echo "configureSh -- -- SECRET_PROJECT_NAME=${SECRET_PROJECT_NAME} =-"
echo "configureSh -- -- RABBITMQ_MIG_NAME_RAW=${RABBITMQ_MIG_NAME_RAW} =-"
echo "configureSh -- -- RABBITMQ_CLUSTER_HOSTS=${RABBITMQ_CLUSTER_HOSTS} =-"

echo "configureSh -- -- SECRET_NAME_RABBITMQ_CRED=${SECRET_NAME_RABBITMQ_CRED} =-"
echo "configureSh -- -- LDAP_SERVER=${LDAP_SERVER} =-"
echo "configureSh -- -- SECRET_NAME_LDAP_CRED=${SECRET_NAME_LDAP_CRED} =-"
echo "configureSh -- -- SECRET_NAME_CELERY_CRED=${SECRET_NAME_CELERY_CRED} =-"
echo "configureSh -- -- API_HOST=${API_HOST} =-"
echo "configureSh -- -- SECRET_API_KEY_ID=${SECRET_API_KEY_ID} =-"
echo "configureSh -- -- VHOST=${VHOST} =-"
echo "configureSh -- -- API_HOST=${API_HOST} =-"
echo "configureSh -- -- SECRET_API_KEY_ID=${SECRET_API_KEY_ID} =-"
echo "configureSh -- -- REGION=${REGION} =-"
echo "configureSh -- -- VHOST=${VHOST} =-"

export API_KEY_ID="$(gcloud secrets versions access latest --secret="${SECRET_API_KEY_ID}" --project="${SECRET_PROJECT_NAME}")"

envsubst < /etc/advanced_config_ldap.tmpl > /etc/rabbitmq/advanced.tmpl
sed -i "s|@USER@|${USER}|g;s|@PASSWORD@|${PASSWORD}|g;s|@|$|g" /etc/rabbitmq/advanced.tmpl
sed -i "s|@api_host@|${API_HOST}|g;s|@api_key_id@|${API_KEY_ID}|g" /usr/local/sbin/monitoring.py
sed -i "s|@project@|${SECRET_PROJECT_NAME}|g" /usr/local/sbin/service_account_key.sh
cat /etc/rabbitmq/advanced.tmpl

install_runtime_scripts() {
    local source_dir="/opt/rabbitmq-init/scripts"

    if [ ! -d "$source_dir" ]; then
        source_dir="/tmp/envvar/scripts"
    fi

    if [ ! -d "$source_dir" ]; then
        echo "[ERROR] Runtime scripts folder not found" >&2
        exit 1
    fi

    cp "$source_dir"/*.sh /usr/local/sbin/
    chmod +x /usr/local/sbin/*.sh
    chmod +x /usr/local/sbin/join-cluster.py
}

create_rabbitmq_wrapper() {
    cat <<EOF > /usr/local/sbin/rabbitmq.sh
#!/bin/bash
set -euo pipefail

chmod 755 /etc/pki/tls
chmod +x /usr/local/sbin/cert.sh
chmod +x /usr/local/sbin/rabbitmq_config.sh
chmod +x /usr/local/sbin/rabbitmq-ldap.sh
chmod +x /usr/local/sbin/logging.sh
chmod +x /usr/local/sbin/join-cluster.py

/usr/local/sbin/rabbitmq_config.sh "${SECRET_NAME_RABBITMQ_CRED}" "${SECRET_PROJECT_NAME}" "${SECRET_NAME_CELERY_CRED}" "${VHOST}"
/usr/local/sbin/cert.sh "${RABBITMQ_CLUSTER_HOSTS}" "${REGION}" "${SECRET_SAN_NODE_CERT}" "${SECRET_SAN_NODE_KEY}" "${SECRET_PROJECT_NAME}"
/usr/local/sbin/rabbitmq-ldap.sh "${SECRET_NAME_LDAP_CRED}" "${SECRET_PROJECT_NAME}"
/usr/local/sbin/logging.sh
systemctl restart rabbitmq-server.service
EOF
    chmod +x /usr/local/sbin/rabbitmq.sh
}

create_cluster_wrapper() {
    cat <<EOF > /usr/local/sbin/rabbitmq-cluster.sh
#!/bin/bash
set -euo pipefail

sleep 30
/usr/bin/python3.9 /usr/local/sbin/join-cluster.py --secret "${SECRET_NAME_RABBITMQ_CRED}" --hosts "${RABBITMQ_CLUSTER_HOSTS}"
EOF
    chmod +x /usr/local/sbin/rabbitmq-cluster.sh
}

configure_cron_jobs() {
    chmod +x /usr/local/sbin/service_log.sh
    (crontab -l 2>/dev/null; echo "0 */8 * * * /bin/bash /usr/local/sbin/service_log.sh") | crontab -

    chmod +x /usr/local/sbin/monitoring.py
    (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/bin/python3.9 /usr/local/sbin/monitoring.py") | crontab -
}

echo "Installing runtime shell scripts"
install_runtime_scripts

echo "Creating rabbitmq service wrapper"
create_rabbitmq_wrapper

echo "Creating clustering service wrapper"
create_cluster_wrapper

echo "Configuring cron jobs"
configure_cron_jobs