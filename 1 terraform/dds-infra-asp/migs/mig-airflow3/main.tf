locals {
  load_balancer_ips = [
    {
      name = "airflow3",
      ip   = module.airflow_MIG.airflow_lb_address
    },
    {
      name = "rabbit3"
      ip   = module.rabbitmq_MIG.rabbitmq_lb_address
    }
  ]
}

module "rabbitmq_MIG" {
  source                    = "../../modules/mig‑rabbitmq"
  project                   = var.project
  region                    = var.region
  zone                      = var.zone
  env                       = var.env_suffix
  provisioning_model        = var.provisioning_model
  instance_template_name_prefix = "rabbitmq3‑template"
  firewall_tags             = concat(var.common_fw, var.rabbitmq_firewall_tags)
  machine_type              = var.rabbitmq_machine_type
  boot_disk_image           = var.rabbitmq_boot_disk_image
  image_project             = var.project
  kms_key_self_link         = var.kms_key_self_link
  subnetwork0               = var.subnetwork0
  subnetwork1               = var.subnetwork1
  service_account_scopes    = ["cloud‑platform"]
  service_account_email     = var.service_account_email
  health_check_name         = "rabbitmq3‑health"
  port                      = var.rabbitmq_port
  MIG_manager_name          = "rabbitmq3‑group"
  wait_for_instances        = false
  base_instance_name        = "rabbitmq3‑dds"
  distribution_policy_zones = var.distribution_policy_zones
  target_size               = var.rabbitmq_target_size
  backend_service_name      = "rabbitmq3‑backendservice"
  forwarding_rule_name      = "rabbitmq3‑loadbalancer"

  #Rabbit env to parametized for project envs
  secret_san_node_cert      = var.secret_san_node_cert
  secret_san_node_key       = var.secret_san_node_key
  secret_name_rabbitmq_cred = var.secret_name_rabbitmq_cred
  ldap_server               = var.ldap_server
  secret_name_ldap_cred     = var.secret_name_ldap_cred
  secret_name_celery_cred   = var.secret_name_celery_cred
  api_host                  = var.api_host
  secret_api_key_id         = var.secret_api_key_id
  airflow_vhost             = var.airflow_vhost
}

module "airflow_MIG" {
  source                      = "../../modules/mig"
  project                     = var.project
  region                      = var.region
  zone                        = var.zone
  env                         = var.env_suffix
  provisioning_model          = var.provisioning_model
  instance_template_name_prefix = "airflow3‑template"
  firewall_tags               = concat(var.common_fw, var.airflow_firewall_tags)
  machine_type                = var.machine_type
  boot_disk_image             = var.airflow_boot_disk_image
  boot_disk_type              = var.airflow_boot_disk_type
  image_project               = var.project
  kms_key_self_link           = var.kms_key_self_link
  subnetwork0                 = var.subnetwork0
  subnetwork1                 = var.subnetwork1
  service_account_scopes      = ["cloud‑platform"]
  service_account_email       = var.service_account_email
  health_check_name           = "airflow3‑health"
  port                        = var.port
  MIG_manager_name            = "airflow3‑group"
  wait_for_instances          = false //terraform won't wait for all instance created and
  base_instance_name          = "airflow3‑dds"
  distribution_policy_zones   = var.distribution_policy_zones
  backend_service_name        = "airflow3‑backendservice"
  forwarding_rule_name        = "airflow3‑loadbalancer"
  max_replicas                = var.max_replicas
  min_replicas                = var.min_replicas
  scaler_name                 = "airflow3‑group‑scaler"

  secret_project_name         = var.project
  secret_name_rabbitmq_cred   = var.secret_name_rabbitmq_cred
  secret_name_celery_cred     = var.secret_name_celery_cred
  secret_name_ldap_cred       = var.secret_name_ldap_cred
  secret_name_key             = var.secret_name_key
  secret_name_cert            = var.secret_name_cert
  secret_api_key_id           = var.secret_api_key_id
  secret_san_node_cert        = var.secret_san_node_cert
  secret_san_node_key         = var.secret_san_node_key
  api_host                    = var.api_host

  sql_instance                = var.sql_instance
  sql_user                    = var.sql_user
  cert_key                    = var.cert_key
  cert_crt                    = var.cert_crt
  dag_file_bucket             = var.dag_file_bucket
  rabbitmq_node               = var.rabbitmq_node
  airflow_db                  = var.airflow_db
  server_name                 = var.server_name

  PARALLELISM                 = var.PARALLELISM
  MAX_ACTIVE_TASKS_PER_DAG    = var.MAX_ACTIVE_TASKS_PER_DAG
  MAX_ACTIVE_RUNS_PER_DAG     = var.MAX_ACTIVE_RUNS_PER_DAG
      secret_airflow_key      = var.secret_airflow_key
      log_bucket              = var.log_bucket
      ldap_ou_name            = var.ldap_ou_name
      ldap_server             = var.ldap_server
      base_url                = var.base_url
      web_server_host         = var.web_server_host
      airflow_vhost           = var.airflow_vhost

      depends_on = [module.rabbitmq_MIG]
}

module "gcp-app-dns" {
  source  = "../../modules/dns‑record‑set"

  # put lb {name,ip} in loop only when lb.name is not null
  for_each = { for lb in local.load_balancer_ips : lb.name => lb if lb.name != null }

  project    = var.project
  region     = var.region
  env        = var.env
  continent  = var.continent

  record_names = [
    {
      app_name = "${each.value.name}-${var.env_suffix}"
      type     = "A"
      ttl      = 300
      records  = [ each.value.ip ]
    }
  ]

  depends_on = [module.rabbitmq_MIG, module.airflow_MIG]
}