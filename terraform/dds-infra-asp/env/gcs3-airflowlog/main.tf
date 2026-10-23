module "gcs-temp" {
  source                = "../../modules/gcs-tf"
  project               = var.project
  region                = var.region
  namespace             = var.namespace
  env                   = var.env
  auth_token            = var.auth_token
  compact_project_name  = var.compact_project_name
  labels                = var.labels
  bucket                = var.bucket
}