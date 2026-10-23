project                   = "hsbc‑11505776‑ddshk‑dev"
region                    = "asia‑east2"
zone                      = "asia‑east2‑b"
env_suffix                = "dev"
env                       = "dev" // dev|prod
machine_type              = "e2‑standard‑4"
rabbitmq_machine_type     = "n1‑standard‑1"
provisioning_model        = "standard"
airflow_boot_disk_image   = "hsbc‑rhel8‑3‑2‑airflow‑immutable‑asp‑prod‑20260727073016"
rabbitmq_boot_disk_image  = "hsbc‑rhel‑8‑rabbitmq‑immutable‑asp‑prod‑20260804083016"
kms_key_self_link         = "projects/hsbc‑6320774‑kms‑dev/locations/asia‑east2/keyRings/computeEngine/cryptoKeys/HSComputeEngine"
subnetwork0               = "projects/hsbc‑6320774‑vpc‑host‑asia‑dev/regions/asia‑east2/subnetworks/cinternal‑vpc1‑asia‑east2"
subnetwork1               = "projects/hsbc‑11505776‑ddshk‑dev/regions/asia‑east2/subnetworks/net1‑asia‑east2"
service_account_email     = "dds‑airflow‑gce‑sa@hsbc‑11505776‑ddshk‑dev.iam.gserviceaccount.com"
distribution_policy_zones = ["asia‑east2‑b", "asia‑east2‑c", "asia‑east2‑a"]
rabbitmq_target_size      = 3
max_replicas              = 1
min_replicas              = 1
port                      = "443"
rabbitmq_port             = "15671"
continent                 = "hk"

common_fw = [
  "fwt‑ag‑all‑dev‑out‑efx‑nexus‑3‑production",
  "tt‑6320774‑vpc‑host‑asia‑cinternal‑drn‑a‑i‑ssh",
  "fwt‑ag‑all‑dev‑out‑alm‑github",
  "fwt‑ag‑all‑dev‑out‑alm‑nexus‑3‑uat",
  "fwt‑ag‑all‑dev‑out‑alm‑nexus‑3‑production",
  "fwt‑ag‑all‑dev‑out‑efx‑nexus‑3‑production",
  "fwt‑ag‑all‑dev‑out‑gl‑repo",
  "tt‑10795520‑amgesgds‑onprem‑a‑i‑esgsql",
  "fwt‑ag‑6320774‑dev‑hk‑google‑clouddns",
  "fwt‑ag‑6320774‑dev‑out‑google‑clouddns",
  "fwt‑ag‑6320774‑dev‑out‑hsbc‑dns",
  "fwt‑ag‑all‑dev‑hk‑nessus‑scanner",
  "fwt‑ag‑cloudsql‑access",
  "tt‑11505776‑ddshk‑vdi‑a‑i‑gpcpssh",
  "fwt‑ag‑all‑dev‑out‑ad1ds‑ldap",
  "tt‑11505776‑ddshk‑vpn‑a‑i‑all",
  "tt‑11505776‑ddshk‑vmconnect‑a‑e‑vmconnect",
  "tt‑11505776‑ddshk‑vmconnect‑a‑i‑vmconnect",
  "tt‑11505776‑ddshk‑onprem‑a‑e‑nexus",
  "tt‑11505776‑ddshk‑onprem‑a‑e‑onprem",
  "tt‑11505776‑ddshk‑gcp‑a‑e‑gbmtnexus",
  "tt‑6320774‑dev‑a‑i‑1‑128‑0‑0‑2‑all‑ssh",
  "tt‑10116889‑coe‑drn‑a‑i‑all",
  "linux‑pets",
  "fw‑cinternal‑vpc1‑a‑i‑ilb",
  "t‑all‑dev‑all‑in‑ilb‑healthcheck"
]

airflow_firewall_tags = [
  "tt‑11505776‑ddshk‑airflowha‑a‑i‑rabbitmq",
]

rabbitmq_firewall_tags = [
  "tt‑11505776‑ddshk‑airflowha‑a‑i‑rabbitmq",
]

//metadata
secret_san_node_cert      = "rabbitmq3‑san‑ssl‑cert‑dev"
secret_san_node_key       = "rabbitmq3‑san‑ssl‑key‑dev"
secret_name_key           = "airflow3‑ssl‑key‑dev"
secret_name_cert          = "airflow3‑ssl‑cert‑dev"
secret_name_ldap_cred     = "airflow3‑bind‑user‑dev"
secret_name_celery_cred   = "celery3‑user‑dev"
secret_airflow_key        = "secret‑airflow3‑key‑dev"
secret_name_rabbitmq_cred = "rabbitmq3‑user‑dev"

ldap_server      = "aa‑lds‑prod.hk.hsbc"
ldap_ou_name     = "hsbc‑11505776‑ddshk‑dev"
api_host         = "alert‑api‑key‑hk‑dev"
secret_api_key_id= "nexus382‑GB‑ASP‑DDS‑ACC‑Token" # to do: create proper secret

sql_instance     = "hsbc‑11505776‑ddshk‑dev:asia‑east2:psql3‑metadata‑dev‑tcp:127.0.8.1:5432"
airflow_db       = "airflowdb"
sql_user         = "dds‑airflow‑gce‑dev‑sa@hsbc‑11505776‑ddshk‑dev.iam"

dag_file_bucket  = "ddshk‑dev3‑dds‑data‑dbt‑asp"
log_bucket       = "ddshk‑dev3‑airflow‑log"

cert_key         = "/opt/airflow/cert/airflow‑hk‑dev.hsbc‑11505776‑ddshk‑dev.dev.gcp.cloud.hk.hsbc.key"
cert_crt         = "/opt/airflow/cert/airflow‑hk‑dev.hsbc‑11505776‑ddshk‑dev.dev.gcp.cloud.hk.hsbc.crt"
rabbitmq_node    = "rabbitmq3‑dev.hsbc‑11505776‑ddshk‑dev.dev.gcp.cloud.hk.hsbc"
server_name      = "airflow3‑dev.hsbc‑11505776‑ddshk‑dev.dev.gcp.cloud.hk.hsbc"

PARALLELISM             = "32"
MAX_ACTIVE_TASKS_PER_DAG= "16"
MAX_ACTIVE_RUNS_PER_DAG = "16"
base_url                = "https://airflow3‑dev.hsbc‑11505776‑ddshk‑dev.dev.gcp.cloud.hk.hsbc"
web_server_host         = "0.0.0.0"
airflow_vhost           = "dds"