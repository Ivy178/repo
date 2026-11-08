output "id" {
  value       = local.id
  description = "Disambiguated ID"
}

output "delimiter" {
  value       = local.delimiter
  description = "Delimiter"
}

output "name" {
  value       = local.name
  description = "Normalized name"
}

output "namespace" {
  value       = local.namespace
  description = "Normalized namespace"
}

output "environment" {
  value       = local.environment
}

output "attributes" {
  value       = local.attributes
  description = "Normalized attributes"
}

output "attributes_raw" {
  value       = var.attributes
  description = "Original attributes"
}

output "labels" {
  value       = local.labels
  description = "Normalized Label map"
}