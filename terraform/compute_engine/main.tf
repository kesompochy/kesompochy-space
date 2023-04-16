provider "google" {
  project     = "avid-influence-381703"
  region      = "us-central1"
}

locals {
  master_tag  = "k8s-master"
  worker_tag  = "k8s-worker"
}

resource "google_compute_address" "master" {
  name = "k8s-master-address"
}

resource "google_compute_instance" "master" {
  name         = "k8s-master"
  machine_type = "n1-standard-2"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-lts"
    }
  }

  network_interface {
    network = data.google_compute_network.default.self_link
    access_config {
      nat_ip = google_compute_address.master.address
    }
  }

  tags = [local.master_tag]
}

resource "google_compute_instance" "worker" {
  count        = 1
  name         = "k8s-worker-${count.index}"
  machine_type = "n1-standard-2"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-lts"
    }
  }

  network_interface {
    network = data.google_compute_network.default.self_link
    access_config {
    }
  }

  tags = [local.worker_tag]
}

resource "google_compute_firewall" "k8s_master" {
  name    = "k8s-master"
  network = data.google_compute_network.default.self_link

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = [local.master_tag]
}

resource "google_compute_firewall" "allow_nodeport_traffic" {
  name    = "allow-nodeport-traffic"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["30080", "30443", "80", "443"]
  }

  source_ranges = ["35.191.0.0/16"]

  target_tags = [local.worker_tag]
}

data "google_compute_network" "default" {
  name = "default"
}

resource "google_compute_global_address" "lb" {
  name = "k8s-lb-address"
}

resource "google_compute_instance_group" "worker_group" {
  name       = "k8s-worker-group"
  zone        = "us-central1-a"

  instances = [for worker in google_compute_instance.worker : worker.self_link]

  named_port {
    name = "http"
    port = 30080
  }

  named_port {
    name = "https"
    port = 30443
  }
}

resource "google_compute_backend_service" "backend_service" {
  name = "lb"
  protocol = "TCP"
  port_name = "http"
  timeout_sec = 30
  enable_cdn = false

  backend {
    balancing_mode = "UTILIZATION"
    group = google_compute_instance_group.worker_group.self_link
    capacity_scaler = 1
    max_connections = 0
    max_connections_per_instance = 0
    max_connections_per_endpoint = 0
    max_rate = 0
    max_rate_per_instance = 0
    max_rate_per_endpoint = 0
    max_utilization = 0.8
  }

  timeouts {}

  health_checks = [
    google_compute_health_check.health_check.self_link
  ]
}

resource "google_compute_backend_service" "backend_service_https" {
  name = "lb-https"
  protocol = "TCP"
  port_name = "https"
  timeout_sec = 30
  enable_cdn = false

  backend {
    balancing_mode = "UTILIZATION"
    group = google_compute_instance_group.worker_group.self_link
    capacity_scaler = 1
    max_connections = 0
    max_connections_per_instance = 0
    max_connections_per_endpoint = 0
    max_rate = 0
    max_rate_per_instance = 0
    max_rate_per_endpoint = 0
    max_utilization = 0.8
  }

  timeouts {}

  health_checks = [
    google_compute_health_check.health_check.self_link
  ]
}

resource "google_compute_health_check" "health_check" {
  name = "k8s-healthcheck"
  check_interval_sec = 5
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold= 2
  tcp_health_check {
    port = "30080"
    proxy_header = "NONE"
  }
  timeouts {}
}

resource "google_compute_target_tcp_proxy" "target_tcp_proxy_80" {
  name = "lb-target-proxy-3"
  backend_service = google_compute_backend_service.backend_service.self_link
  timeouts {}
}

resource "google_compute_target_tcp_proxy" "target_tcp_proxy_443" {
  name = "lb-target-proxy-4"
  backend_service = google_compute_backend_service.backend_service_https.self_link
  timeouts {}
}

resource "google_compute_forwarding_rule" "forwarding_rule_80" {
  name = "lb-forwarding-rule-3"
  target = google_compute_target_tcp_proxy.target_tcp_proxy_80.self_link
  port_range = "80"
  ip_address = google_compute_global_address.lb.address
  ip_protocol = "TCP"
}

resource "google_compute_forwarding_rule" "forwarding_rule_443" {
  name = "lb-forwarding-rule-4"
  target = google_compute_target_tcp_proxy.target_tcp_proxy_443.self_link
  port_range = "443"
  ip_address = google_compute_global_address.lb.address
  ip_protocol = "TCP"
}

output "lb-ipaddress" {
  value = google_compute_global_address.lb.address
}