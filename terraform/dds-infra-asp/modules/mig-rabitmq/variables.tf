variable "project" {
  description = "project id"
  type        = string
}

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

variable "target_size" {
  description = "Number of instances in the stateless RabbitMQ MIG"
  type        = number
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

variable "forwarding_rule_name" {
  description = "name of forwarding rule"
  type        = string
}

variable "wait_for_instances" {
  type = bool
}

variable "secret_san_node_cert" {
  description = "Secret name for RabbitMQ node certificate"
  type        = string
}

variable "secret_san_node_key" {
  description = "Secret name for RabbitMQ node key"
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
  description = "Secret name for LDAP bind credentials"
  type        = string
}

variable "secret_name_celery_cred" {
  description = "Secret name for Celery credentials"
  type        = string
}

variable "api_host" {
  description = "Monitoring API host"
  type        = string
}

variable "secret_api_key_id" {
  description = "Secret API key id"
  type        = string
}

variable "scaler_name" {
  description = "Name prefix of the autoscaler. Leave empty to disable autoscaling."
  type        = string
  default     = ""
}

variable "max_replicas" {
  description = "Maximum number of instances for the autoscaler."
  type        = number
  default     = 3
}

variable "min_replicas" {
  description = "Minimum number of instances for the autoscaler."
  type        = number
  default     = 3
}

variable "provisioning_model" {
  description = "VM provisioning model: auto|spot|standard. When auto, dev/sit/uat => spot and preprod/prod => standard."
  type        = string
  default     = "auto"
}

variable "airflow_vhost" {
  description = "airflow_vhost"
  type        = string
}