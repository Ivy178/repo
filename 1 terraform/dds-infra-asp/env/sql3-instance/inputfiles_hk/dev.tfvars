name = "psql3-metadata"
#psql-instance
private_network  = "hsbc-default-network"
project          = "hsbc-11505776-ddshk-dev"
database_version = "POSTGRES_16"
edition          = "ENTERPRISE"
kms_key_name     = "projects/hsbc-6320774-kms-dev/locations/asia-east2/keyRings/hsbc-11505776-ddshk-dev/cryptoKeys/HSMcloudSQL"
region           = "asia-east2"
zone             = "asia-east2-b"
env              = "dev"
disk_size        = 25
availability_type = "ZONAL"
tier             = "db-custom-2-7424"  //https://cloud.google.com/sql/docs/mysql/instance-settings
iam_user_emails = ["dds-cloudsql1-infra-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com","dds-airflow-gce-dev-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com"]
disk_autoresize  = true
delete_protection = false
ip_v4            = false
disk_type        = "PD_SSD"
db_names         = ["cdlmetadatadb", "airflowdb"]
backup_enabled   = true
database_flags = [
{
  name = "cloudsql.enable_pgaudit"
  value = "on"
},
{
  name = "cloudsql.iam_authentication"
  value = "on"
},
{
  name = "log_connections"
  value = "on"
}
]
user_labels = {
"data_classification" : "restricted",
"bia" : "major",
"terraform" : true
"service_tier" : "tier1"
}