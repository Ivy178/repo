variable "name" {
  type        = string
  description = "The name of the Cloud POSTGRESQL resources"
}

variable "private_network" {
  type        = string
  description = "network name"
}

variable "edition" {
  description = "The Cloud SQL edition to use"
  type        = string
  default     = null
}

variable "project" {
  description = "project id"
}

variable "database_version" {
  description = "The database version to use"
}

variable "kms_key_name" {
  description = "CMEK key"
  type        = string
}

variable "delete_protection" {
  description = "delete protection or not"
  type        = bool
  default     = false
}

variable "ip_v4" {
  description = "IP V4 enabled or not"
  type        = bool
  default     = false
}

variable "iam_user_emails" {
  description = "A list of IAM users to be created in your cluster"
  type        = list(string)
  default     = []
}

variable "region" {
  description = "The region of the Cloud SQL resources"
  type        = string
  default     = "asia-east2"
}

variable "tier" {
  description = "machine-type"
  type        = string
}

variable "zone" {
  description = "The zone for the master instance, it should be something like: `a`, `c`."
  type        = string
  default     = "asia-east2-b"
}

variable "db_names" {
  description = "database name/names if multiple"
  type        = list(string)
  default     = ["airflowdb", "cdlmetadatadb"]
}

variable "db_charset" {
  description = "The charset for the default database."
  type        = string
  default     = ""
}

variable "db_collation" {
  description = "The collation for the default database. Example for MySQL databases: 'utf8_general_ci'."
  type        = string
  default     = ""
}

variable "ssl_mode" {
  description = "set mysql connect ssl"
  type        = string
  default     = "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"
}

variable "disk_autoresize" {
  description = "Configuration to increase storage size"
  type        = bool
}

variable "disk_size" {
  description = "The disk size for the master instance"
  type        = number
}

variable "disk_type" {
  description = "The disk type for the master instance."
  type        = string
  default     = "PD_SSD"
}

variable "env" {
  description = "environment of instance"
  type        = string
}

variable "availability_type" {
  description = "The availability type for the master instance. Can be either `REGIONAL` or `null`."
  type        = string
}

variable "backup_enabled" {
  description = "Set to false if you want to disable backup."
  default     = true
}

variable "backup_start_time" {
  #type = number
  default     = "05:30"
  description = "backup start time"
}

variable "user_labels" {
  description = "labels tag to the sql instance"
  type        = map(any)
  default     = {}
}

variable "backup_location" {
  description = "The region where the backup will be stored. Default locations for backup storage are not permitted due to jurisdictional implications"
  default     = null
}

variable "retained_backups" {
  type        = number
  default     = 7
  description = "number of backups to retain"
}

variable "retention_unit" {
  type        = string
  default     = "COUNT"
  description = "The unit that retained_backups represents"
}

variable "database_flags" {
  description = "You use database flags for many operations, including adjusting MySQL parameters, adjusting options, and configuring and tuning an instance"
  type = list(object({
    name  = string
    value = string
  }))
}