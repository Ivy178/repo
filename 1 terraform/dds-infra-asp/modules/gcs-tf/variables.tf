variable "project" {
  type        = string
  description = "Project ID/Name"
}

variable "region" {
  type        = string
  description = "Project region"
}

variable "namespace" {
  type        = string
  description = "Project namespace"
}

variable "env" {
  type        = string
  description = "enviro ment"
}

variable "compact_project_name" {
  type        = string
  description = "Compact project name"
}

variable "labels" {
  type        = map(any)
  description = "Labels for resource"
}

variable "lifecyclePolicyRequired" {
  description = "Determine if the bucket should be required the lifecycle policy, when setting true need to fill the var.lifecycle_rules"
  type        = bool
  default     = null
}

variable "bucket" {
  type = object({
    bucket_purpose         = string,
    location               = string,
    storage_class          = string,
    bucket_policy_only     = bool,
    force_destroy          = bool,
    kms_key_name           = string,
    retention_policy_rules = list(map(string)),
    # lifecycle_rules = list(object({action = any,condition = any})),
    iam_binding            = list(object({ role = string, members = list(string) }))
  })
  description = "Bucket Details"
}

variable "lifecycle_rules" {
  description = "The bucket's Lifecyle Rules configuration."
  type = list(object({
    action    = any
    condition = any
  }))
  default = [{
    action = { # Delete, SetStorageClass
      type = "Delete"
      #type = "SetStorageClass"
      #storage_class = NEARLINE, COLDLINE, ARCHIVE (Required if action type is SetStorageClass)
    }
    condition = { # age, created_before, with_state, matches_storage_class, num_newer_versions
      age = 90
    }
  }]
}

variable "auth_token" {
  type = string
}