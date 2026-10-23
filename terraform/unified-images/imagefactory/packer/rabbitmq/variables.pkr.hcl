hcl
  
variable "nexus_pass" {
  type = string
  description = "gbmt nexus password"
  sensitive = true
}

variable "project_id" {
  type = string
  description = "GCP project id on which image will be build"
}

variable "image_encryption_key" {
  type = string
  description = "CMEK encryption key for VM"
}

variable "region" {
  type = string
  description = "GCP region to which deploy the VM"
}

variable "zone" {
  type = string
  description = "GCP zone to which deploy the VM"
}

variable "machine_type" {
  type = string
  description = "GCP type of the machine"
  default = "n1-standard-1"
}

variable "image_description" {
  type = string
  description = "Self explained"
  default = "Cloud SQL Proxy mutable image for hk dev environemnt"
}

variable "image_name" {
  type = string
  description = "Self explained"
  default = "hsbc-rhel-8-stage3-rabbitmq"
}

variable "image_family" {
  type = string
  description = "Self explained"
  default = "hsbc-rhel-8-java-rabbitmq"
}

variable "disk_size" {
  type = number
  description = "Self explained"
  default = 20
}

variable "network_project_id" {
  type = string
  description = "Project id of network to which vm will be connected to"
}

variable "network" {
  type = string
  description = "Network for vm"
  default = ""
}

variable "subnetwork" {
  type = string
  description = "Name of the subnetwork to which vm will be connected to"
}

variable "source_image_project_id" {
  type = string
  description = "Project id for source image"
  default = "hsbc-6320774-distcompute-prod"
}

variable "source_image_family" {
  type = string
  description = "Family name of source image"
  default = "gce-rhel8-ver2-stage2"
}

variable "ssh_username" {
  type = string
  description = "ssh username for private key"
}

variable "tags" {
  type = list(string)
  description = "List of tags to attach to the vm"
}

variable "scopes" {
  type = string
  description = "Defaults to all scopes"
  default = "https://www.googleapis.com/auth/cloud-platform"
}

variable "in_development" {
  type = string
  description = ""
  default = ""
}

variable "git_sha" {
  type = string
  description = "SSH key for packer to connect with"
  default = "none"
}

variable "up_status" {
  type = string
  description = "Status for the VM"
  default = "none"
}

variable "service_account_email" {
  type = string
  description = "Service account email"
}

variable "nexus_user" {
  type = string
  description = "gbmt nexus user"
}

variable "env_type" {
  type = string
  description = "Type of the environment"
}

variable "environment" {
  type = string
  description = "Environment name"
  default = ""
}

variable "image_type" {
  type = string
  description = "Type of the image to build options are mutable or immutable"
}

variable "lock_script" {
  type = string
  description = "Shell script used for stage3 lockdown"
  default = "../../stage3_lock/stage3_lock_vm.sh"
}