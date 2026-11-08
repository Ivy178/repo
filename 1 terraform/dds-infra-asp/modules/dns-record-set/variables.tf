variable "project" {
  description = "Project id for the zone."
  type        = string
}

variable "record_names" {
  description = "List of records to create"
  default     = []
  type = list(
    object({
      app_name = string
      type     = string
      ttl      = number
      records  = list(string)
    })
  )
}

variable "region" {}

variable "env" {}

variable "continent" {}