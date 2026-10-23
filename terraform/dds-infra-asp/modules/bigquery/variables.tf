variable "region" {
description = "region of the project or resource"
}
 
variable "env" {
description = "prod or non-prod"
}
 
variable "user_by_email" {
description = "email-id details"
}
 
variable "eim_id" {
default = ""
}
 
variable "kms_key_name" {
description = "CMEK key"
type        = string
}
 
variable "project" {
description = "name of the project"
}
 
variable "hase_members" {
description = "Identities that will be granted the privilege in role for HASE dataset."
type        = list(string)
}
 
variable "ss_writer_sa" {
type        = list(string)
description = ""
}
 
variable "datasets" {
description = "A map of objects, including datasets IDs, roles and views"
type        = map(list(map(list(map(string)))))
default     = {}
}