provider "google" {
  project      = var.project
  access_token = var.auth_token
  region       = var.region
}

module "gcs_label" {
  source                = "../tf-dds-gcp-label"
  namespace             = var.namespace
  env                   = var.env
  name                  = var.compact_project_name
  attributes            = [lookup(var.bucket, "bucket_purpose")]
  delimiter             = "-"
  labels                = var.labels
}

resource "google_storage_bucket" "bucket_backend" {
  name                          = module.gcs_label.id
  location                      = lookup(var.bucket, "location")
  uniform_bucket_level_access   = lookup(var.bucket, "bucket_policy_only")
  storage_class                 = lookup(var.bucket, "storage_class")
  force_destroy                 = lookup(var.bucket, "force_destroy")
  labels                        = module.gcs_label.labels

  encryption {
    default_kms_key_name = lookup(var.bucket, "kms_key_name")
  }

  versioning {
    enabled = lookup(var.bucket, "versioning", true)
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecyclePolicyRequired == true ? var.retention_policy_rules : []
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
      }
      condition {
        age                  = lookup(lifecycle_rule.value.condition, "age", null)
        created_before       = lookup(lifecycle_rule.value.condition, "created_before", null)
        with_state           = lookup(lifecycle_rule.value.condition, "with_state", lookup(lifecycle_rule.value.condition, "is_live", false) ? "LIVE" : null)
        matches_storage_class = lookup(lifecycle_rule.value.condition, "matches_storage_class", null)
        num_newer_versions   = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
      }
    }
  }
}

dynamic "lifecycle_rule" {
  for_each = var.lifecyclePolicyRequired == true ? var.retention_policy_rules : []
  content {
    action {
      type          = lifecycle_rule.value.action.type
      storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
    }
    condition {
      age                  = lookup(lifecycle_rule.value.condition, "age", null)
      created_before       = lookup(lifecycle_rule.value.condition, "created_before", null)
      with_state           = lookup(lifecycle_rule.value.condition, "with_state", lookup(lifecycle_rule.value.condition, "is_live", false) ? "LIVE" : null)
      matches_storage_class = lookup(lifecycle_rule.value.condition, "matches_storage_class", null)
      num_newer_versions   = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
    }
  }
}

dynamic "retention_policy" { #Optional
  for_each = lookup(var.bucket, "retention_policy_rules")
  content {
    is_locked        = lookup(retention_policy.value, "retention_policy_lock", true)
    retention_period = lookup(retention_policy.value, "retention_policy_retention_period", null)
  }
}

resource "google_storage_bucket_iam_binding" "bucket_be_binding" {
  count  = length(lookup(var.bucket, "iam_binding"))          //iam_binding可能会有许多member
  bucket = google_storage_bucket.bucket_backend.name
  role   = lookup(element(lookup(var.bucket, "iam_binding"), count.index), "role")
  members = lookup(element(lookup(var.bucket, "iam_binding"), count.index), "members")

  depends_on = [
    google_storage_bucket.bucket_backend
  ]
}