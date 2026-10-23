output "secret_manager_id" {
  value = [
    for secret in google_secret_manager_secret.secret :
    secret.secret_id
  ]
  description = "Unique id for the dataset being provisioned"
}