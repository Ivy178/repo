output "airflow_load_balancer_ip" {
  value       = module.airflow_MIG.airflow_lb_address
  description = "Ip address for Airflow Load balancer"
}

output "rabbitmq_load_balancer_ip" {
  value       = module.rabbitmq_MIG.rabbitmq_lb_address
  description = "Ip address for Airflow Load balancer"
}