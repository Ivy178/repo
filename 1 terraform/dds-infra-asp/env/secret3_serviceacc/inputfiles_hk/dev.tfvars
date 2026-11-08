project     = "hsbc-11505776-ddshk-dev"
region      = "asia-east2"
env         = "dev"
expire_time = ""
kms_key_name = "projects/hsbc-6320774-kms-dev/locations/asia-east2/keyRings/hsbc-11505776-ddshk-dev/cryptoKeys/HSMsecretMgr"
secrets = {
  "airflow3-ssl-cert" = [
    "group:gcp.hsbc-11505776-ddshk-dev.devops-team-priv@hsbc.com",
    "serviceAccount:dds-gce-infra-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com",
    "serviceAccount:dds-airflow-gce-dev-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com"
  ],
  "airflow3-ssl-key" = [
    "group:gcp.hsbc-11505776-ddshk-dev.devops-team-priv@hsbc.com",
    "serviceAccount:dds-gce-infra-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com",
    "serviceAccount:dds-airflow-gce-dev-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com"
  ],
  "airflow3-bind-user" = [
    "group:gcp.hsbc-11505776-ddshk-dev.devops-team-priv@hsbc.com",
    "serviceAccount:dds-gce-infra-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com",
    "serviceAccount:dds-airflow-gce-dev-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com"
  ],
  "rabbitmq3-san-ssl-key" = [
    "group:gcp.hsbc-11505776-ddshk-dev.devops-team-priv@hsbc.com",
    "serviceAccount:dds-gce-infra-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com",
    "serviceAccount:dds-airflow-gce-dev-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com"
  ],
  "rabbitmq3-san-ssl-cert" = [
    "group:gcp.hsbc-11505776-ddshk-dev.devops-team-priv@hsbc.com",
    "serviceAccount:dds-gce-infra-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com",
    "serviceAccount:dds-airflow-gce-dev-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com"
  ],
  "rabbitmq3-user" = [
    "group:gcp.hsbc-11505776-ddshk-dev.devops-team-priv@hsbc.com",
    "serviceAccount:dds-gce-infra-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com",
    "serviceAccount:dds-airflow-gce-dev-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com"
  ],
  "celery3-user" = [
    "group:gcp.hsbc-11505776-ddshk-dev.devops-team-priv@hsbc.com",
    "serviceAccount:dds-gce-infra-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com",
    "serviceAccount:dds-airflow-gce-dev-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com"
  ],
  "secret-airflow3-key" = [
    "group:gcp.hsbc-11505776-ddshk-dev.devops-team-priv@hsbc.com",
    "serviceAccount:dds-gce-infra-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com",
    "serviceAccount:dds-airflow-gce-dev-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com"
  ]
}

labels = {
  "data_classification" : "restricted",
  "bia" : "major",
  "terraform" : true
  "service_tier" : "tier1"
}