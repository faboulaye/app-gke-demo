provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_global_address" "external-address" {
  name = "lb-external-address"
}

resource "google_compute_global_forwarding_rule" "forwarding-rule" {
  name       = "lb-forwarding-rule"
  ip_address = google_compute_global_address.external-address.address
  port_range = "80"
  target     = google_compute_target_http_proxy.http-proxy.self_link
}

resource "google_compute_url_map" "url-map" {
  name            = "lb-url-map"
  default_service = google_compute_backend_service.backend-service.self_link
}

resource "google_compute_target_http_proxy" "http-proxy" {
  name    = "lb-http-proxy"
  url_map = google_compute_url_map.url-map.self_link
}

resource "google_compute_backend_service" "backend-service" {
  name                  = "webapp-backend-service"
  protocol              = "HTTP"
  port_name             = "http-port"
  timeout_sec           = 10
  load_balancing_scheme = "EXTERNAL"
  session_affinity      = "NONE"
  backend {
    group = google_compute_instance_group_manager.instance-group.instance_group
  }
  health_checks = [google_compute_health_check.health-check.self_link]
}


resource "google_compute_health_check" "health-check" {
  name                = "webapp-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    request_path = "/"
    port         = "80"
  }
}

resource "google_compute_instance_group_manager" "instance-group" {
  name        = "webapp-instance-group"
  description = "Terraform test instance group"
  version {
    name              = "v1"
    instance_template = google_compute_instance_template.template.self_link
  }
  zone               = var.zone
  base_instance_name = "webapp"
  target_size        = 3
  named_port {
    name = "http-port"
    port = 80
  }
  auto_healing_policies {
    health_check      = google_compute_health_check.health-check.self_link
    initial_delay_sec = 300
  }
}

resource "google_compute_autoscaler" "autoscaler" {
  name   = "webapp-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.instance-group.self_link

  autoscaling_policy {
    max_replicas    = 10
    min_replicas    = 3
    cooldown_period = 60
    cpu_utilization {
      target = 0.5
    }
  }
}

// VM Template
resource "google_compute_instance_template" "template" {
  name        = "webapp-template"
  description = "This template is used to create apache server instances."

  tags = ["http-tag", "webapp", "apache"]

  labels = {
    environment = "dev"
  }
  instance_description = "Apache web server"
  machine_type         = "f1-micro"

  metadata_startup_script = file("init.sh")

  // Create a new boot disk from an image
  disk {
    source_image = "debian-cloud/debian-9"
    auto_delete  = true
    boot         = true
  }
  network_interface {
    network = google_compute_network.network.name
    access_config {

    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_firewall" "firewall" {
  name        = "webapp-firewall"
  description = "Allow http exchange"
  network     = google_compute_network.network.name
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-tag"]
}

resource "google_compute_network" "network" {
  name = "webapp-network"
}

