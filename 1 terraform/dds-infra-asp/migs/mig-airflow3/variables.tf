variable "project" {
  description = "project id"
  default    = "hsbc‑11505776‑ddshk‑dev"
}

variable "region" {
  description = "The region of the resources"
  type        = string
  default     = "asia‑east2"
}

variable "zone" {
  description = "The zone for the resource, it should be something like: `a`, `c`."
  type        = string
  default     = "asia‑east2‑b"
}

variable "env" {
  description = "environment of resource"
  type        = string
  default     = "dev"
}

variable "env_suffix" {
  type        = string
  description = "suffix for dns creation"
}

variable "common_fw" {
  description = "firewall tags of the instance under this group"
}

variable "airflow_firewall_tags" {
  description = "firewall tags of the instance under this group"
}

variable "rabbitmq_firewall_tags" {
  description = "firewall tags of the instance under this group"
}

variable "machine_type" {
  description = "machine type of the instance under this group"
}

variable "airflow_boot_disk_image" {
  type        = string
  description = "Boot image name used for compute VMs."
}

variable "airflow_boot_disk_type" {
  type        = string
  description = "Boot disk type used for airflow instances (e.g. pd-balanced, pd-ssd)."
  default     = "pd-balanced"
}

variable "rabbitmq_boot_disk_image" {
  type        = string
  description = "Boot image name used for compute VMs."
}

variable "kms_key_self_link" {
  description = "kms key for compute engine"
}

variable "subnetwork0" {
  description = "shared VPC as primary network"
}

variable "subnetwork1" {
  description = "default network as secondary instance"
}

variable "service_account_email" {
  description = "SA mailbox"
}

variable "distribution_policy_zones" {
  description = "instances' zone "
}

variable "port" {
  description = "The port configuration"
}

variable "rabbitmq_port" {
  description = "The port configuration"
}

variable "max_replicas" {
  description = "The maximum number of instances that the autoscaler can scale up to"
}

variable "min_replicas" {
  description = "The minimum number of replicas that the autoscaler can scale down to. This cannot be less than 0."
}

variable "continent" {
  default = "in"
}

variable "rabbitmq_machine_type" {
  description = "machine type of the instance under this group"
}

variable "rabbitmq_target_size" {
  description = "Initial target size for the RabbitMQ MIG"
  type        = number
}

variable "provisioning_model" {
  description = "VM Model"
  type        = string
  default     = "auto"
}

variable "secret_san_node_cert" {
  description = "Secret name for RabbitMQ SAN node certificate"
  type        = string
}

variable "secret_san_node_key" {
  description = "Secret name for RabbitMQ SAN node private key"
  type        = string
}

variable "secret_name_rabbitmq_cred" {
  description = "Secret name for RabbitMQ credentials"
  type        = string
}

variable "ldap_server" {
  description = "LDAP server endpoint"
  type        = string
}

variable "secret_name_ldap_cred" {
  description = "Secret name for LDAP credentials"
  type        = string
}
variable "api_host" {
  description = "API host for monitoring script"
  type        = string
}

variable "secret_api_key_id" {
  description = "Secret API key id"
  type        = string
}

variable "sql_instance" {
  description = "sql_instance"
  type        = string
}

variable "sql_user" {
  description = "sql_user"
  type        = string
}

variable "cert_key" {
  description = "cert_key"
  type        = string
}

variable "cert_crt" {
  description = "cert_crt"
  type        = string
}

variable "secret_name_key" {
  description = "secret_name_key"
  type        = string
}

variable "secret_name_cert" {
  description = "secret_name_key"
  type        = string
}

variable "dag_file_bucket" {
  description = "dag_file_bucket"
  type        = string
}

variable "rabbitmq_node" {
  description = "rabbitmq_node"
  type        = string
}

variable "airflow_db" {
  description = "airflow_db"
  type        = string
}

variable "server_name" {
  description = "server_name"
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