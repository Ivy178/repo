#!/bin/bash
service_account_list=("juniper@project_id.iam.gserviceaccount.com")
touch /etc/rabbitmq/sa_key.log
for email in ${service_account_list[*]}; do
    echo $email
    service_account=`echo $email | sed 's/ */%/g'`
    export BEFORE_DATE=`date --date="-60 day ago" +%Y-%m-%d`
    gcloud iam service-accounts keys list --iam-account ${service_account} --managed-by=user --filter="CREATED_AT<${BEFORE_DATE}" --format "table[no-heading](KEY_ID,CREATED_AT:sort=t)" | cut -d " " -f1 |
    while read KEY; do
        if grep -Fxq "${KEY}" /etc/rabbitmq/sa_key.log
        then
            echo "alert already sent."
        else
            echo "key creation is more than 60 days for key ${KEY} of service account ${service_account}" >> /etc/rabbitmq/sa_key_detail.log
            echo "${KEY}" >> /etc/rabbitmq/sa_key.log
        fi
    done
done