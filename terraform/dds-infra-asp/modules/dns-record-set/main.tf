locals {
  gcp_continent         = var.continent # gcp continent value: hk/uk/us
  gcp_env               = var.env       # gcp environment: dev/prod
  gcp_service_project_id = var.project
  gcp_dns_subdomain     = "${local.gcp_service_project_id}.${local.gcp_env}.gcp.cloud.${local.gcp_continent}.hsbc." # No need to change this
}

resource "google_dns_record_set" "cloud-static-records" {
  project      = var.project
  managed_zone = var.project

  for_each = { for record in var.record_names : join("/", [record.app_name, record.type]) => record }

  name = (
    each.value.app_name != "" ?
    "${each.value.app_name}.${local.gcp_dns_subdomain}" :
    "${var.region}.${local.gcp_dns_subdomain}"
  )

  type    = each.value.type
  ttl     = each.value.ttl
  rrdatas = each.value.records
}