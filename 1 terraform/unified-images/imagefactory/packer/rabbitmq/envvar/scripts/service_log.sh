#!/bin/bash

filename='/etc/rabbitmq/service.log'
if [ -f "$filename" ]; then
    rm -rf "$filename"
    echo "$filename is removed"
fi