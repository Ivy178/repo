locals {
  labels = {
    managed-by = "terraform"
    environment = lower(var.env)
  }
  env_lower = lower(var.env)
  auto_provisioning_model = contains(["dev", "sit", "uat"], local.env_lower) ? "spot" : "standard"
  effective_provisioning_model = lower(var.provisioning_model) == "auto" ? local.auto_provisioning_model : lower(var.provisioning_model)
  use_spot_instance = local.effective_provisioning_model == "spot"
}

resource "google_compute_instance_template" "instance_tpl" {
  description = "This template is used to create app server instances."

  name_prefix = "${var.instance_template_name_prefix}-${lower(var.env)}-"
  tags        = var.firewall_tags
  machine_type= var.machine_type

  disk {
    source_image = "projects/${var.image_project}/global/images/${var.boot_disk_image}"
    disk_type    = var.boot_disk_type
    auto_delete  = true
    boot         = true
    disk_encryption_key {
      kms_key_self_link = var.kms_key_self_link
    }
  }

  network_interface {
    subnetwork = var.subnetwork0
  }

  network_interface {
    subnetwork = var.subnetwork1
  }

  labels = {
    environment        = lower(var.env)
    data_classification = "restricted"
    bia                = "major"
    service_tier       = "tier1"
  }

  metadata = {
    env                    = var.env
    disable-legacy-endpoints = true
    sql-instance           = var.sql_instance
    sql-user               = var.sql_user
    cert-key               = var.cert_key
    cert-crt               = var.cert_crt
    secret-project-name    = var.secret_project_name
      secret-name-key          = var.secret_name_key
    secret-name-cert         = var.secret_name_cert
    secret-name-ldap-cred    = var.secret_name_ldap_cred
    dag-file-bucket          = var.dag_file_bucket
    rabbitmq-node            = var.rabbitmq_node
    secret-name-rabbitmq-cred = var.secret_name_rabbitmq_cred
    secret-name-celery-cred  = var.secret_name_celery_cred
    secret-san-node-cert     = var.secret_san_node_cert
    secret-san-node-key      = var.secret_san_node_key
    region                   = var.region
    api-host                 = var.api_host
    secret-api-key-id        = var.secret_api_key_id
    airflow-db               = var.airflow_db
    server-name              = var.server_name
    parallelism              = var.PARALLELISM
    max-active-tasks-per-dag = var.MAX_ACTIVE_TASKS_PER_DAG
    max-active-runs-per-dag  = var.MAX_ACTIVE_RUNS_PER_DAG
    secret-airflow-key       = var.secret_airflow_key
    log-bucket               = var.log_bucket
    ldap-ou-name             = var.ldap_ou_name
    ldap-server              = var.ldap_server
    base-url                 = var.base_url
    web-server-host          = var.web_server_host
    vhost                    = var.airflow_vhost
}

// Availability policies
scheduling {
  preemptible              = local.use_spot_instance
  automatic_restart        = local.use_spot_instance ? false : true
  on_host_maintenance      = local.use_spot_instance ? "TERMINATE" : "MIGRATE"
  provisioning_model       = local.use_spot_instance ? "SPOT" : "STANDARD"
  instance_termination_action = local.use_spot_instance ? "STOP" : null
}

service_account {
  scopes = var.service_account_scopes
  email  = var.service_account_email
}

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_health_check" "instance_health_check" {
  name                = "${var.health_check_name}-${lower(var.env)}"
  check_interval_sec  = 10
  timeout_sec         = 10
  healthy_threshold   = 2
  unhealthy_threshold = 10 # 50 seconds

  https_health_check {
    port         = var.port
    request_path = "/api/v2/monitor/health"
  }
}

resource "google_compute_region_instance_group_manager" "instance_group_manager" {
  name                         = "${var.MIG_manager_name}-${lower(var.env)}"
  wait_for_instances           = var.wait_for_instances
  base_instance_name           = "${var.base_instance_name}-${lower(var.env)}"
  region                       = var.region
  distribution_policy_zones    = var.distribution_policy_zones
  #distribution_policy_target_shape = "balanced"

  version {
    name             = "appserver"
    instance_template = google_compute_instance_template.instance_tpl.self_link
  }

  auto_healing_policies {
    health_check        = google_compute_health_check.instance_health_check.self_link
    initial_delay_sec   = 600
  }

  update_policy {
    type               = "PROACTIVE"
    minimal_action     = "REPLACE"
    max_unavailable_fixed = 0
    max_surge_fixed      = 3
  }

  depends_on = [google_compute_instance_template.instance_tpl]
}

resource "google_compute_region_autoscaler" "region_autoscaler" {
  provider = google-beta
  name     = "${var.scaler_name}-${lower(var.env)}"
  region = var.region
  target = google_compute_region_instance_group_manager.instance_group_manager.self_link

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = 60

    cpu_utilization {
      target = 0.8
    }

    metric {
      name = "agent.googleapis.com/memory/percent_used"
      filter = "resource.type = \"gce_instance\" AND metric.labels.state = \"used\""
      type  = "GAUGE"
      target = 80.0
    }
  }

  depends_on = [google_compute_region_instance_group_manager.instance_group_manager]
}

resource "google_compute_region_backend_service" "instance_backend_service" {
  description = "Add Instance Group into backend_service."
  name        = "${var.backend_service_name}-${lower(var.env)}"
  region      = var.region
  session_affinity = "NONE"
  health_checks = [google_compute_health_check.instance_health_check.self_link]

  backend {
    group = google_compute_region_instance_group_manager.instance_group_manager.instance_group
    balancing_mode = "CONNECTION"
  }
}

resource "google_compute_forwarding_rule" "vector_forwarding_rule" {
  name                  = "${var.forwarding_rule_name}-${lower(var.env)}"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.instance_backend_service.self_link
  all_ports             = true
  subnetwork            = var.subnetwork0

  #no need static ip, use random ip and output, then it will be bind to airflow FQDN
  # ip_address         = var.ip_address
}

