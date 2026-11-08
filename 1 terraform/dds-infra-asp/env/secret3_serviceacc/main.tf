module "secret_manager" {
  source        = "../../modules/cloud_secret_manager"
  secrets       = var.secrets
  project       = var.project
  env           = var.env
  auth_token    = var.auth_token
  region        = var.region
  kms_key_name  = var.kms_key_name
  expire_time   = var.expire_time
  labels        = var.labels
}