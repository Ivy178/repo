#!/bin/bash
 
export SERVICES_TO_BE_DISABLED=(
google-startup-scripts
google-shutdown-scripts
sshd
)
 
for SERVICE in "${SERVICES_TO_BE_DISABLED[@]}"
do
echo "stop, disable and mask ${SERVICE}"
systemctl stop ${SERVICE}
systemctl disable ${SERVICE}
systemctl mask ${SERVICE}
done
 
remove all users but system users
 
for user in $(awk -F ':' '$3>=1000 {print $1}' /etc/passwd)
do
echo "deleting user $user"
userdel -f $user
echo "Done deleting user $user"
done