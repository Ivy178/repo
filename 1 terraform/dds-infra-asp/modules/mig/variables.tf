variable "project" {
  description = "project id"
  type        = string
}

# variable "auth_token" {
#   type = string
# }

variable "region" {
  description = "The region of the resources"
  type        = string
}

variable "zone" {
  description = "The zone for the resource, it should be something like: `a`, `c`."
  type        = string
}

variable "env" {
  description = "environment of resource"
  type        = string
}

variable "subnetwork0" {
  description = "shared VPC"
  type        = string
}

variable "subnetwork1" {
  description = "network of Cloud SQL instance is placed "
  type        = string
}

variable "machine_type" {
  description = "VM Machine Type"
  type        = string
}

variable "kms_key_self_link" {
  description = "The key used to encrypt VM boot disk"
  type        = string
}

variable "service_account_scopes" {
  description = "scope for service account "
  type        = list(string)
}

variable "service_account_email" {
  description = "SA mailbox"
  type        = string
}

variable "health_check_name" {
  description = "health check name"
  type        = string
}

variable "MIG_manager_name" {
  description = "name of Instance Group Manager"
  type        = string
}

variable "base_instance_name" {
  description = "instance name of the instance under this group"
  type        = string
}

variable "distribution_policy_zones" {
  description = "instances zone "
  type        = list(string)
}

variable "forwarding_rule_name" {
  description = "name of forwarding rule"
  type        = string
}

variable "instance_template_name_prefix" {
  description = "name prefix for instance template of instance group"
  type        = string
}

variable "firewall_tags" {
  description = "Target tags added to instances for firewall and networking."
  type        = list(string)
}

variable "boot_disk_image" {
  type        = string
  description = "Boot image name used for compute VMs."
}

variable "boot_disk_type" {
  type        = string
  description = "Boot disk type for instance template (e.g. pd‑balanced, pd‑ssd)."
  default     = "pd‑balanced"
}

variable "image_project" {
  type        = string
  description = "Project name of the image"
}

variable "port" {
  description = "The port configuration"
  type        = string
}

variable "backend_service_name" {
  description = "name of backend"
  type        = string
}

variable "wait_for_instances" {
  type = bool
}

variable "scaler_name" {
  description = "name of the autoscaler"
  type        = string
}

variable "max_replicas" {
  description = "The maximum number of instances that the autoscaler can scale up to."
}

variable "min_replicas" {
  description = "The minimum number of replicas that the autoscaler can scale down to. This cannot be less than 0."
}

variable "bucket_startup_script" {
  type        = string
  description = "bucket to store start‑up scripts"
  default     = ""
}

variable "provisioning_model" {
  description = "VM provisioning model: auto|spot|standard. When auto, dev/sit/uat => spot and preprod/prod => standard."
  type        = string
  default     = "auto"
}

// add var for metadata1
variable "sql_instance" {
  description = ""
  type        = string
}

variable "sql_user" {
  description = ""
  type        = string
}

variable "cert_key" {
  description = ""
  type        = string
}

variable "cert_crt" {
  description = ""
  type        = string
}

variable "secret_project_name" {
  description = ""
  type        = string
}

variable "secret_name_key" {
  description = ""
  type        = string
}

variable "secret_name_cert" {
  description = ""
  type        = string
}

variable "secret_name_ldap_cred" {
  description = ""
  type        = string
}

variable "dag_file_bucket" {
  description = ""
  type        = string
}

variable "rabbitmq_node" {
  description = ""
  type        = string
}
variable "secret_name_rabbitmq_cred" {
  description = ""
  type        = string
}

variable "secret_name_celery_cred" {
  description = ""
  type        = string
}

variable "secret_san_node_cert" {
  description = ""
  type        = string
}

variable "secret_san_node_key" {
  description = ""
  type        = string
}

variable "api_host" {
  description = ""
  type        = string
}

variable "secret_api_key_id" {
  description = ""
  type        = string
}

variable "airflow_db" {
  description = ""
  type        = string
}

variable "server_name" {
  description = ""
  type        = string
}

variable "PARALLELISM" {
  description = "PARALLELISM"
  type        = string
}

variable "MAX_ACTIVE_TASKS_PER_DAG" {
  description = "MAX_ACTIVE_TASKS_PER_DAG"
  type        = string
}

variable "MAX_ACTIVE_RUNS_PER_DAG" {
  description = "MAX_ACTIVE_RUNS_PER_DAG"
  type        = string
}

variable "secret_airflow_key" {
  description = "secret_airflow_key"
  type        = string
}

variable "log_bucket" {
  description = "log_bucket"
  type        = string
}

variable "ldap_ou_name" {
  description = "ldap_ou_name"
  type        = string
}

variable "ldap_server" {
  description = "ldap_server"
  type        = string
}

variable "base_url" {
  description = "base_url"
  type        = string
}

variable "web_server_host" {
  description = "web_server_host"
  type        = string
}

variable "airflow_vhost" {
  description = "airflow_vhost"
  type        = string
}