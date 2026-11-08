#!/bin/sh
export _PIP_LOCATIONS_NO_WARN_ON_MISMATCH=1
export PIP_ROOT_USER_ACTION=ignore
export PATH=$PATH:/usr/local/bin

#Installing python and required packages for Python3 & Airflow.
declare DNF_PACKAGES=(python39 python39-pip python39-devel bzip2 bzip2-devel gcc gcc-c++ gdbm gdbm-devel git libffi-devel
        ncurses ncurses-devel openssl openssl-devel python39-setuptools readline
        readline-devel redhat-rpm-config tk tk-devel xz xz-devel openldap-devel tcl-devel
        libuuid-devel socat wget)

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

install_dnf_packages "${DNF_PACKAGES[@]}"

mkdir /opt/tmp

python3.9 -V

cp /tmp/linux/pip.conf /etc/pip.conf
sed -i "s/#\#nexus/$nexus_user:$nexus_pass/g" /etc/pip.conf
mkdir -p /etc/rabbitmq
cp /tmp/envvar/configure.sh /usr/local/sbin/configure.sh

# Stage runtime scripts used by configure.sh during first boot.
mkdir -p /opt/rabbitmq-init/scripts
cp /tmp/envvar/scripts/*.sh /opt/rabbitmq-init/scripts/
chmod +x /opt/rabbitmq-init/scripts/*.sh

# Install Python components.
python3.9 -m pip install wheel
python3.9 -m pip install --upgrade pip
python3.9 -m pip install --upgrade setuptools
python3.9 -m pip install --upgrade google-compute-engine
python3.9 -m pip install --no-cache-dir -U crcmod
python3.9 -m pip install requests==2.32.4
python3.9 -m pip install ushlex
python3.9 -m pip install google-api-python-client==1.12.11
python3.9 -m pip install google-cloud-logging==3.2.1
python3.9 -m pip install google-cloud-secret-manager==2.16.3
python3.9 -m pip install google-auth==2.23.2
python3.9 -m pip install python-dateutil==2.8.2

echo "installRabbitMQ -- upgrade pip and install virtualenv..."
python3.9 -m pip install --upgrade pip setuptools wheel

cp /tmp/systemd/*.service /usr/lib/systemd/system

#Set-up Monitoring config
cp /tmp/config/monitoring.py /usr/local/sbin/monitoring.py

#Set-up logging config
cp /tmp/config/logging.conf /usr/local/sbin/logging.conf
cp /tmp/config/service_account_key.sh /usr/local/sbin/service_account_key.sh

#Set-up Clustering script
cp /tmp/config/join-cluster.py /usr/local/sbin/join-cluster.py

# Install Erlang
echo "Install Erlang"
curl -kv --user ${nexus_user}:${nexus_pass} https://nexus302.systems.uk.hsbc:8081/nexus/repository/misc-foss-n3p/com/hsbc/vpb/erlang/27.3.4.6-1.el8/erlang-27.3.4.6-1.el8-x86_64.rpm -o erlang-27.3.4.6-1.el8-x86_64.rpm
rpm -ivh erlang-27.3.4.6-1.el8-x86_64.rpm

# Install RabbitMQ
echo "Install RabbitMQ"
curl -kv --user ${nexus_user}:${nexus_pass} https://nexus302.systems.uk.hsbc:8081/nexus/repository/misc-foss-n3p/com/hsbc/rabbitmq-server/4.2.3-1.el8/rabbitmq-server-4.2.3-1.el8-noarch.rpm -o rabbitmq-server-4.2.3-1.el8-noarch.rpm
rpm -ivh rabbitmq-server-4.2.3-1.el8-noarch.rpm

cp /tmp/config/rabbitmq.tmpl /etc/rabbitmq.conf
cp /tmp/config/rabbitmq-env.conf /etc/rabbitmq/rabbitmq-env.conf
cp /tmp/config/advanced_config_ldap.tmpl /etc/advanced_config_ldap.tmpl

# Configure RabbitMQ Server
echo "Configure RabbitMQ-Server"

#yum -q makecache -y --disablerepo='*' --enablerepo='rabbitmq_server'

sudo service rabbitmq-server status
chkconfig rabbitmq-server on
/sbin/service rabbitmq-server start

sudo rabbitmq-plugins enable rabbitmq_management
sudo rabbitmq-plugins enable rabbitmq_auth_mechanism_ssl
sudo rabbitmq-plugins enable rabbitmq_auth_backend_ldap
sudo rabbitmq-plugins enable rabbitmq_prometheus

systemctl enable env-configure.service

systemctl enable rabbitmq.service
systemctl enable clustering.service