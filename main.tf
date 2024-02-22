provider "google" {
  credentials = file(var.credentialsFile)
  project     = var.projectId
  region      = var.region
}


resource "google_compute_network" "vpc" {
 
  name                            = "webapp-vpc"
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "webapp_subnet" {
  name          = "webapp-subnet"
  region        = var.region
  network       = google_compute_network.vpc.self_link
  ip_cidr_range = "10.0.0.0/24"
}

resource "google_compute_subnetwork" "db_subnet" {

  name          = "db-subnet"
  region        = var.region
  network       = google_compute_network.vpc.self_link
  ip_cidr_range = "10.100.0.0/24"
}

resource "google_compute_route" "webapp_route" {

  name             = "webapp-route"
  network          = google_compute_network.vpc.self_link
  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
  tags             = ["webapp-subnet"]
}

resource "google_compute_instance" "default" {
  name         = "my-instance"
  machine_type = "n2-standard-2"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "projects/cloudassignment03-413923/global/images/packer-1708561578"
      size  = 100
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.webapp_subnet.self_link
  }

  service_account {
    email  = "csye-gcp-assignment04-sa@cloudassignment03-413923.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_firewall" "rules" {
  project     = var.projectId
  name        = "my-firewall-rule"
  network     = google_compute_network.vpc.self_link
  description = "Creates firewall rule targeting tagged instances"

  allow {
    protocol = "tcp"
    ports    = ["3002"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["webapp-subnet"]
}