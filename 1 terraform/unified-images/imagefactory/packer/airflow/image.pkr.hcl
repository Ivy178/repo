locals {
  image_name = format("%s-%s", var.image_name, formatdate("YYYYMMDDhhmmss", timestamp()))
  image_family = format("%s", var.image_family)
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
  default = "Airflow mutable image for dev environemnt"
}

variable "image_name" {
  type = string
  description = "Self explained"
  default = "hsbc-rhel-8-stage3-airflow"
}

variable "image_family" {
  type = string
  description = "Self explained"
  default = "hsbc-rhel-8-java-airflow"
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

variable "service_account_email" {
  type = string
  description = "Service account email"
}

variable "EnvType" {
  type = string
  description = "Type of the environment"
}

variable "up_status" {
  type = string
  description = "Status for the VM"
  default = "none"
}

variable "image_type" {
  type = string
  description = "Type of the image to build options are mutable or immutable"
}

variable "lock_script" {
  type = string
  description = "Shell script for locking VMs on GCP"
  default = "../../stage3_lock/stage3_lock_vm.sh"
}

variable "nexus_user" {
  type = string
  description = "nexus user"
}

variable "nexus_pass" {
  type = string
  description = "nexus_pass"
  sensitive = true
}
// 启动临时虚拟机、制作镜像。
source "googlecompute" "google-airflow" {
  service_account_email = var.service_account_email
  project_id = var.project_id
  source_image_project_id = [var.source_image_project_id]
  source_image_family = var.source_image_family
  use_os_login = true
  ssh_username = var.ssh_username
  region = var.region
  zone = var.zone
  machine_type = var.machine_type
  image_description = var.image_description
  image_name = local.image_name
  image_family = local.image_family
  disk_size = var.disk_size
  network_project_id = var.network_project_id
  network = var.network
  subnetwork = var.subnetwork
  omit_external_ip = true
  use_internal_ip = true
  disk_encryption_key {
    kmsKeyName = var.image_encryption_key
  }
  image_encryption_key {
    kmsKeyName = var.image_encryption_key
  }
  labels = {
    owner = var.EnvType
  }
  image_labels = {
    up_status = var.up_status
  }
  tags = var.tags
  scopes = [var.scopes]
}

build {
  sources = ["source.googlecompute.google-airflow"]
  provisioner "file" {
    source = "./config"
    destination = "/tmp"
  }

  provisioner "file" {
    source = "./envvar"
    destination = "/tmp"
  }

  provisioner "file" {
    source = "./linux"
    destination = "/tmp"
  }

  provisioner "file" {
    source = "./systemd"
    destination = "/tmp"
  }

  provisioner "shell" {
    environment_vars = [
      "EnvType=${var.EnvType}",
      "nexus_user=${var.nexus_user}",
      "nexus_password=${var.nexus_pass}"
    ]
    execute_command = "sudo -S env {{ .Vars }} {{ .Path }}"     // 把environment_vars、script传进去
    script = "./install.sh"
  }

  provisioner "shell" {
    execute_command = "sudo -S sh -c {{ .Vars }} bash {{ .Path }}"
    inline = [
      "echo [Airflow] Run Crowd Strike Step",
      "rm -rf /tmp/crowdstrike,*.rpm||echo 0",
      "find / -type d -name .git -prune -exec rm -rf {} +",
      "ls -laF /tmp"
    ]
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} bash {{ .Path }}"
    inline = [
      "mkdir -p /tmp/stage3_lock/"
    ]
  }

  provisioner "file" {
    source = "${var.lock_script}"
    destination = "/tmp/stage3_lock/stage3_lock_vm.sh"
  }

  provisioner "shell" {
    execute_command = "echo 'packer' | sudo -S sh -c '{{ .Vars }} bash {{ .Path }}'"
    inline = [
      "echo [Airflow] Run LockDown Stript if lockdown Immutable:${var.image_type} is true",
      format("if [[ %s = \"immutable\" ]]; then", var.image_type),       // 判断image_type是否等于immutable
      "  sudo bash /tmp/stage3_lock/stage3_lock_vm.sh;",
      "fi"
    ]
  }

  provisioner "shell" {
    execute_command = "sudo -S sh -c {{ .Vars }} bash {{ .Path }}"
    inline = [
      "echo delete [Rabbit] LockDown Stript",
      "rm -rf /tmp/stage3_lock/stage3_lock_vm.sh"
    ]
  }
}