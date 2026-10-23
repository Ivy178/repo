
module "bigquery" {
  source          = "../../modules/bigquery"
  eim_id          = var.eim_id
  project         = var.project
  region          = var.region
  ss_writer_sa    = var.ss_writer_sa
  datasets        = var.datasets
  env             = var.env
  kms_key_name    = var.kms_key_name
  user_by_email   = var.user_by_email
  hase_members    = var.hase_members
}