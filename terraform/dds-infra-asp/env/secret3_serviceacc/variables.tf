variable "project" {
  description = "The ID of the project in which the resource belongs."
  type        = string
}

variable "region" {
  description = "The canonical IDs of the location to replicate data."
  type        = string
}

variable "secrets" {
  type        = map(list(string))
  description = "Name of the secrets and members"
}

variable "kms_key_name" {
  description = "CMEK key"
  type        = string
}

variable "expire_time" {
  type        = string
  description = "time-stamp when the secret is scheduled to expire"
}

variable "env" {
  description = "Environment to provision resources."
  type        = string
}

variable "labels" {
  description = "labels tag to the sql instance"
  type        = map(any)
  default     = {}
}

variable "auth_token" {
  type = string
}