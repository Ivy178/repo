provider "google" {
  project     = var.project
  access_token = var.auth_token
  region      = var.region
}
locals {
  labels = {
    managed-by = "terraform"
    environment = lower(var.env)
  }
}

//secret to store Credentials
resource "google_secret_manager_secret" "secret" {
  for_each   = var.secrets
  secret_id  = "${each.key}-${var.env}"
  project    = var.project
  labels     = merge(local.labels, var.labels)
  expire_time = var.expire_time
  replication {
    user_managed {
      replicas {
        location = var.region
        customer_managed_encryption {
          kms_key_name = var.kms_key_name
        }
      }
    }
  }
}

// IAM Binding for secrets
resource "google_secret_manager_secret_iam_binding" "binding" {
  for_each   = var.secrets
  project    = var.project
  secret_id  = google_secret_manager_secret.secret[each.key].secret_id
  role       = "roles/secretmanager.secretAccessor"
  members    = each.value
}