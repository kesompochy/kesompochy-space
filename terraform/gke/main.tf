provider "google" {
  project = "avid-influence-381703"
}

resource "google_container_cluster" "cluster" {
  name               = "kesompochy-space"
  location           = "us-central1-a"
  initial_node_count = 3

  node_config {
    machine_type = "n1-standard-2"
  }

  master_auth {

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}