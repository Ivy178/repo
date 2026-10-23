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

variable "bucket" {
  type = object({
    bucket_purpose        = string,
    location              = string,
    storage_class         = string,
    bucket_policy_only    = bool,
    force_destroy         = bool,
    kms_key_name          = string,
    retention_policy_rules = list(map(string)),
    iam_binding = list(object({ role = string, members = list(string) }))
  })
  description = "Bucket Details"
}

variable "auth_token" {
  type = string
}