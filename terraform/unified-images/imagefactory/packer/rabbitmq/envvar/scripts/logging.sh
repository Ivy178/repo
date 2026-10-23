#!/bin/bash

current_node=$(curl --header "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/name)

sed -i "s|@server_name@|${current_node}|g" /usr/local/sbin/logging.conf
cp /usr/local/sbin/logging.conf /etc/google-fluentd/config.d/
systemctl restart google-fluentd
systemctl status google-fluentd -l