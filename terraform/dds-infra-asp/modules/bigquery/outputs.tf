provider "google" {
project = var.project
region  = var.region
}
 
locals {
env          = var.env
project      = var.project
project_name = coalesce(var.project, format("%s-%s", local.project, local.env))
priv         = local.env == "prod" ? "-priv" : ""
}
 
resource "google_bigquery_dataset" "main" {
for_each              = var.datasets
project               = local.project_name
dataset_id            = upper("{each.key}_{local.env}")
location              = var.region
delete_contents_on_destroy = true
default_encryption_configuration {
kms_key_name = var.kms_key_name
}
 
labels = {
terraformed      = "true"
eim_id           = var.eim_id
project          = local.project_name
environment      = local.env
data_classification = "restricted"
bia              = "major"
service_tier     = "tier1"
}
 
lifecycle {
prevent_destroy = false
#prevent_destroy = true
}
}
 
// added bigquery viewer role for bigquery read access SA
 
resource "google_bigquery_dataset_iam_binding" "hase_reader" {
project = local.project_name
for_each = {
for key, value in var.datasets : key => value
if strcontains(upper(key),"HASE") && strcontains(upper(key), "DEV")
}
dataset_id = upper("{each.key}_{local.env}")
role       = "roles/bigquery.dataViewer"
members = var.hase_members
}