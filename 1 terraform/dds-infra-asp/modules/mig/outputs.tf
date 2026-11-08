output "airflow_lb_address" {
  value       = google_compute_forwarding_rule.vector_forwarding_rule.ip_address
  description = "Internal ip address of Airflow Load balancer"
}