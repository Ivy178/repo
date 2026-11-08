output "gcs_bucket_name" {
  value = google_storage_bucket.bucket_backend.name
}

output "bucket" {
  description = "The created storage bucket"
  value       = google_storage_bucket.bucket_backend
}