provider "google" {
  project = var.project
  region  = var.region
}

locals {
  labels = {
    name        = lower(var.name)
    environment = lower(var.env)
  }
  name     = format("%s-%s", local.labels.name, local.labels.environment)
  iam_users = [for account in var.iam_user_emails : {
    email         = account,
    is_account_sa = trimsuffix(account, "gserviceaccount.com") == account ? false : true     //dds-cloudsql1-infra-sa@hsbc-11505776-ddshk-dev.iam.gserviceaccount.com
  }]
}

data "google_compute_network" "private_network" {
  project = var.project
  provider = google
  name    = var.private_network
}

resource "google_sql_database_instance" "instance" {
  provider             = google
  project              = var.project
  name                 = format(local.name)
  region               = var.region
  database_version     = veditionar.database_version
  deletion_protection  = var.delete_protection
  encryption_key_name  = var.kms_key_name

  settings {
              = var.edition
    disk_autoresize  = var.disk_autoresize
    availability_type = var.availability_type
    disk_size        = var.disk_size
    disk_type        = var.disk_type
    #tier machine-type
    tier = var.tier
    ip_configuration {
      ipv4_enabled = var.ip_v4
      private_network = data.google_compute_network.private_network.self_link
      ssl_mode   = var.ssl_mode
    }
    user_labels = merge(local.labels, var.user_labels)
  }

  backup_configuration {
    enabled = var.backup_enabled
    #GCP-CSQL-CTRL-32 - all backup locations must be specified
    location    = var.backup_location
    start_time  = var.backup_start_time
    #Mandatory for Postgres in production
    #point_in_time_recovery_enabled = var.point_in_time_recovery_enabled
    #transaction_log_retention_days = var.transaction_log_retention_days
    backup_retention_settings {
      retained_backups = var.retained_backups
      retention_unit   = var.retention_unit
    }
  }

  dynamic "database_flags" {
    for_each = var.database_flags
    content {
      name  = lookup(database_flags.value, "name", null)
      value = lookup(database_flags.value, "value", null)
    }
  }

  location_preference {
    zone = var.zone
  }
}

resource "google_sql_database" "default" {
  depends_on = [google_sql_user.iam_account]
  count      = length(var.db_names)
  name       = var.db_names[count.index]     //循环创建DB
  project    = var.project
  instance   = google_sql_database_instance.instance.name
  charset    = var.db_charset
  collation  = var.db_collation
}

resource "google_sql_user" "iam_account" {
  for_each = {
    for iu in local.iam_users :
    "${iu.email}_${iu.is_account_sa}" => iu
  }
  project  = var.project
  name = each.value.is_account_sa ? (
    trimsuffix(each.value.email, ".gserviceaccount.com")
  ) : (
    each.value.email
  )

  instance = google_sql_database_instance.instance.name
  type     = each.value.is_account_sa ? "CLOUD_IAM_SERVICE_ACCOUNT" : "CLOUD_IAM_USER"

  depends_on = [google_sql_database_instance.instance]
}