#!/bin/bash

export _PIP_LOCATIONS_NO_WARN_ON_MISMATCH=1
export PIP_ROOT_USER_ACTION=ignore
export PATH=$PATH:/usr/local/bin

##############################################################################

set -e

##############################################################################

echo "------------------------------------------------------------"
echo "Show current user"
echo "------------------------------------------------------------"

echo "Current user is" $(whoami)

echo "------------------------------------------------------------"
echo "Install yum packages"
echo "------------------------------------------------------------"

PYTHON_VERSION="3.12"
PYTHON_BIN="python3.12"
// 这些是 Linux 的软件包名称，不是一组工具命令。脚本通过 dnf install 安装它们，主要用于构建环境
declare DNF_PACKAGES=(bzip2 bzip2-devel gcc gcc-c++ gdbm gdbm-devel git libffi-devel
                      ncurses ncurses-devel openssl openssl-devel readline
                      readline-devel redhat-rpm-config tk tk-devel xz xz-devel openldap-devel tcl-devel
                      fuse libuuid-devel java-11 sqlite-devel gnupg)
declare PYTHON_DNF_PACKAGES=()

dnf update -y

dnf install -y ${DNF_PACKAGES[@]}

// 选择适合的 Python 版本包
select_python_packages() {
    if dnf list --available python3.12 >/dev/null 2>&1; then
        PYTHON_DNF_PACKAGES=(python3.12 python3.12-pip python3.12-devel)    //pip 是 Python 的包管理工具，用来安装、升级或卸载 Python 库（也称“包”）。
    elif dnf list --available python312 >/dev/null 2>&1; then
        PYTHON_DNF_PACKAGES=(python312 python312-pip python312-devel)
    else
        echo "[ERROR] Python ${PYTHON_VERSION} packages not found in configured repositories"
        exit 1
    fi
}

install_dnf_packages() {
    local pkg=("$@")
    echo "[DEBUG] Installing yum Packages ${pkg[@]}"
    dnf update
    for packages in "${pkg[@]}"
    do
      echo "[DEBUG] Installing $packages"
      dnf install -y $packages
    done
    echo "[DEBUG] Installed Packages ${pkg[@]}"
}

select_python_packages
install_dnf_packages "${PYTHON_DNF_PACKAGES[@]}"


if ! command -v "${PYTHON_BIN}" >/dev/null 2>&1; then
  echo "[ERROR] ${PYTHON_BIN} binary not found after package installation"
  exit 1
fi

echo "------------------------------------------------------------"
echo "Create directories"
echo "------------------------------------------------------------"

mkdir /run/airflow
mkdir -p /opt/airflow
mkdir -p /opt/airflow/config
mkdir -p /opt/airflow/modules
mkdir -p /opt/airflow/bigtable_sc
mkdir -p /opt/airflow/cert
mkdir -p /opt/terraform
mkdir /etc/cloudsql
mkdir /opt/tmp
chmod -R 755 /opt/airflow
sudo mkdir -p /opt/cloud-sql-proxy

echo "------------------------------------------------------------"
echo "Check python version"
echo "------------------------------------------------------------"

${PYTHON_BIN} -V

echo "------------------------------------------------------------"
echo "Configure PIP and env"
echo "------------------------------------------------------------"

cp /tmp/linux/pip.conf /etc/pip.conf
sed -i "s/##nexus/$nexus_user:$nexus_password/g" /etc/pip.conf

export PIP_CONFIG_FILE=/etc/pip.conf

cp /tmp/envvar/configure.sh /usr/local/sbin/configure.sh
cp /tmp/envvar/airflow_dag_serialize_once.sh /usr/local/sbin/airflow_dag_serialize_once.sh
cp /tmp/envvar/airflow_seed_variables.sh /usr/local/sbin/airflow_seed_variables.sh

echo "------------------------------------------------------------"
echo "Install basic python packages"
echo "------------------------------------------------------------"

${PYTHON_BIN} -m pip install --upgrade pip
${PYTHON_BIN} -m pip install wheel
${PYTHON_BIN} -m pip install --upgrade setuptools
${PYTHON_BIN} -m pip install --upgrade wheel
${PYTHON_BIN} -m pip install --upgrade google-compute-engine
${PYTHON_BIN} -m pip install --no-cache-dir -U crcmod

echo "------------------------------------------------------------"
echo "Check for proxy"
echo "------------------------------------------------------------"

ps -ef | grep proxy

echo "------------------------------------------------------------"
echo "Configure LVM"
echo "------------------------------------------------------------"

# Extent /opt folder size to 8 GB
lvextend -rL +6G /dev/mapper/vg00-lv_opt

echo "------------------------------------------------------------"
echo "Download cloud sql proxy"
echo "------------------------------------------------------------"

curl -s "https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64" -o /opt/cloud-sql-proxy/cloud_sql_proxy
chmod +x /opt/cloud-sql-proxy/cloud_sql_proxy

echo "------------------------------------------------------------"
echo "Install apache-airflow and dependencies"
echo "------------------------------------------------------------"

cp /tmp/config/airflow_constraints.txt /opt/airflow/airflow_constraints.txt
mkdir -p /opt/tmp/pip-cache /opt/tmp/pip-tmp
export PIP_TMP_DIR=/opt/tmp/pip-tmp
export PIP_CACHE_DIR=/opt/tmp/pip-cache
${PYTHON_BIN} -m pip install --no-cache-dir apache-airflow==3.2.2 --requirement /opt/airflow/airflow_constraints.txt
${PYTHON_BIN} -m pip install --no-cache-dir "apache-airflow[celery,rabbitmq]==3.2.2" --requirement /opt/airflow/airflow_constraints.txt
${PYTHON_BIN} -m pip install --no-cache-dir apache-airflow-providers-fab --requirement /opt/airflow/airflow_constraints.txt
${PYTHON_BIN} -m pip install --no-cache-dir --constraint /opt/airflow/airflow_constraints.txt dbt-core==1.11.8
${PYTHON_BIN} -m pip install --no-cache-dir --constraint /opt/airflow/airflow_constraints.txt dbt-bigquery==1.11.1
${PYTHON_BIN} -m pip install --no-cache-dir cloud-sql-python-connector==1.12.0
${PYTHON_BIN} -m pip install --no-cache-dir python-ldap
${PYTHON_BIN} -m pip check
${PYTHON_BIN} -m pip cache purge || true
rm -rf /opt/tmp/pip-tmp/*
## post-validation connecioor/beam/pandas/google-providers

cp /tmp/systemd/*.service /usr/lib/systemd/system
cp /tmp/systemd/airflow /etc/sysconfig
cp /tmp/systemd/airflow.conf /usr/lib/tmpfiles.d

export AIRFLOW_HOME=/opt/airflow
echo "export AIRFLOW_HOME=/opt/airflow" >> /etc/profile
echo $AIRFLOW_HOME

#copyig custom celery config file
cp /tmp/config/celery_config_ssl.py /opt/airflow/config/platform_celery.py
cp /tmp/config/celery_config_ssl.py /opt/airflow/config/default_celery.py
cp /tmp/config/airflow.tmpl /opt/airflow/airflow.tmpl
cp /tmp/config/webserver_config_ldap.tmpl /opt/airflow/webserver_config_ldap.tmpl

# set-up fluentd airflow config
cp /tmp/linux/fluentd_airflow_dags.conf /etc/google-fluentd/config.d/airflow_dags.conf

# Set-up Monitoring config
cp /tmp/config/monitoring.py /usr/local/sbin/monitoring.py

# Set-up Logging config
cp /tmp/config/logging.conf /usr/local/sbin/logging.conf

echo "------------------------------------------------------------"
echo "Download and install nginx"
echo "------------------------------------------------------------"

wget --no-check-certificate --auth-no-challenge \
--user="${nexus_user}" --password="${nexus_password}" \
"https://nexus02.systems.uk.hsbc:8081/nexus/repository/misc-foss-n3p/com/hsbc/cmb/baasleap/nginx/1.23.2/nginx-1.23.2.tar.gz" \
-O /opt/airflow/nginx-1.23.2.tar.gz
tar zxvf /opt/airflow/nginx-1.23.2.tar.gz
cd nginx-1.23.2/
./configure --with-http_ssl_module --with-http_stub_status_module --prefix=/usr/local/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf
make
make install
nginx -version

cp /tmp/config/nginx.tmpl /etc/nginx/nginx.tmpl

echo "------------------------------------------------------------"
echo "Download and install gcsfuse"
echo "------------------------------------------------------------"

wget --no-check-certificate --auth-no-challenge \
--user="${nexus_user}" --password="${nexus_password}" \
"https://nexus02.systems.uk.hsbc:8081/nexus/repository/tpvr-quantexa/org/gcsfuse/gcsfuse/2.10.0-1/gcsfuse-2.10.0-1.rpm" \
-O /opt/airflow/gcsfuse-2.10.0-1.rpm
rpm -ivh /opt/airflow/gcsfuse-2.10.0-1.rpm

echo "------------------------------------------------------------"
echo "Configure services"
echo "------------------------------------------------------------"

systemctl enable env-configure.service
systemctl enable cloud-sql-proxy.service
systemctl enable cloud-sql-multinic-route.service
systemctl enable certs-ldap.service
systemctl enable gcs_fuse.service
systemctl enable rabbitmq.service
systemctl enable airflow-db-upgrade.service
systemctl enable airflow-dag-reserialize.service
systemctl enable airflow-api-server.service
systemctl enable nginx.service
systemctl enable airflow-scheduler.service
systemctl enable airflow-dag-processor.service
systemctl enable airflow-triggerer.service
systemctl enable celery-worker.service
systemctl enable flower.service

echo "------------------------------------------------------------"
echo "Final checks"
echo "------------------------------------------------------------"

echo "Checking if /usr/local/bin/airflow exists"
test -e /usr/local/bin/airflow

echo "Checking if /usr/local/bin/airflow is executable"
test -x /usr/local/bin/airflow

exit 0

# for debug only

SERVICE="env-configure.service"; echo "Service $SERVICE is $(systemctl is-active $SERVICE)"
SERVICE="cloud-sql-proxy.service"; echo "Service $SERVICE is $(systemctl is-active $SERVICE)"
SERVICE="cloud-sql-multinic-route.service"; echo "Service $SERVICE is $(systemctl is-active $SERVICE)"
SERVICE="certs-ldap.service"; echo "Service $SERVICE is $(systemctl is-active $SERVICE)"
SERVICE="gcs_fuse.service"; echo "Service $SERVICE is $(systemctl is-active $SERVICE)"
SERVICE="rabbitmq.service"; echo "Service $SERVICE is $(systemctl is-active $SERVICE)"
SERVICE="nginx.service"; echo "Service $SERVICE is $(systemctl is-active $SERVICE)"
SERVICE="airflow-scheduler.service"; echo "Service $SERVICE is $(systemctl is-active $SERVICE)"
SERVICE="celery-worker.service"; echo "Service $SERVICE is $(systemctl is-active $SERVICE)"
SERVICE="flower.service"; echo "Service $SERVICE is $(systemctl is-active $SERVICE)"