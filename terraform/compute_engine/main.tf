provider "google" {
  project = "avid-influence-381703"
}

resource "google_compute_instance" "vm_instance" {
  name         = "kesompochy-master"
  machine_type = "n1-standard-2"
  zone         = "us-central1-a"

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = "default"

    access_config {
        nat_ip = google_compute_address.kesompochy_space_static_ip.address
    }
  }

  tags = ["kesompochy-space-allow-external-access"]
}

resource "google_compute_address" "kesompochy_space_static_ip" {
  name         = "kesompochy-space-static-ip"
  address_type = "EXTERNAL"
  region       = "us-central1"
}

resource "google_compute_firewall" "kesompochy_space_allow_external_access" {
  name    = "kesompochy-space-allow-external-access"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "6443"]
  }

  source_ranges = ["0.0.0.0/0"]
}