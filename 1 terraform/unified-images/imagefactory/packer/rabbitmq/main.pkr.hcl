hcl
  
# Install plugin Packer from Anton Kulikov for better view.
locals {
  image_name = format("%s-4-2-%s-%s", var.image_name, var.image_type, formatdate("YYYYMMDDhhmmss", timestamp()))
  image_family = format("%s-%s", var.image_family, var.image_type)
}

source "googlecompute" "google-rabbitmq" {
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
    owner = var.environment
  }
  image_labels = {
    up_status = var.up_status
  }
  tags = var.tags
  scopes = [var.scopes]
}

build {
  sources = ["source.googlecompute.google-rabbitmq"]

  provisioner "file" {
    source = "${path.cwd}/config"
    destination = "/tmp"
  }

  provisioner "file" {
    source = "${path.cwd}/envvar"
    destination = "/tmp"
  }

  provisioner "file" {
    source = "${path.cwd}/linux"
    destination = "/tmp"
  }

  provisioner "file" {
    source = "${path.cwd}/systemd"
    destination = "/tmp"
  }

  provisioner "shell" {
    environment_vars = [
      "env_type=${var.env_type}",
      "nexus_user=${var.nexus_user}",
      "nexus_pass=${var.nexus_pass}"
    ]
    execute_command = "sudo -S env {{ .Vars }} {{ .Path }}"
    script = "${path.cwd}/install.sh"
  }

  provisioner "shell" {
    execute_command = "sudo -S sh -c {{ .Vars }} bash {{ .Path }}"
    inline = [
      "echo [Rabbit] Run Crowd Strike Step",
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
      "echo [Airflow] Run LockDown Script if lockdown Immutable:${var.image_type} is true",
      format("if [[ %s = \"immutable\" ]]; then", var.image_type),
      "sudo bash /tmp/stage3_lock/stage3_lock_vm.sh;",
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