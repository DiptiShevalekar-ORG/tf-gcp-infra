provider "google" {
  credentials = file(var.credentialsFile)
  project     = var.projectId
  region      = var.region
}

# locals {
#   vpc_names = [for i in range(var.num_vpc) : "csye-vpc-${i}"]
# }

resource "google_compute_network" "vpc" {

  name                    = "webapp-vpc"
  auto_create_subnetworks = false
  routing_mode            = var.mode
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "webapp_subnet" {
  name          = "webapp-subnet"
  region        = var.region
  network       = google_compute_network.vpc.self_link
  ip_cidr_range = var.webapp_cIDR_Range  
}

resource "google_compute_subnetwork" "db_subnet" {
  name          = "db-subnet"
  region        = var.region
  network       = google_compute_network.vpc.self_link
  ip_cidr_range = var.DB_CIDR_Range
}

resource "google_compute_route" "webapp_route" {
  name                  = "webapp-route"
  network               = google_compute_network.vpc.self_link
  dest_range            = "0.0.0.0/0"
  next_hop_gateway      = "default-internet-gateway"
  priority              = 1000
  tags                  = ["webapp"]
}

resource "google_compute_address" "gcpcomputeaddress" {
  project = var.projectId
  name = var.gcpcomputeaddressName
  address_type =  "EXTERNAL"
  ip_version = var.IPVersion
}

resource "google_compute_instance" "instance" {
  name         = var.vmname
  machine_type = "n2-standard-2"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.ImagePath
      size  = 100
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.webapp_subnet.self_link
    access_config {
      nat_ip = google_compute_address.gcpcomputeaddress.address
    }
  }

  service_account {
    email  = var.email
    scopes = ["cloud-platform"]
  }

  tags = ["webapp"]

}

resource "google_compute_firewall" "vmfirewallrule" {

  name    = var.firewallRuleName
  network = google_compute_network.vpc.self_link
  allow {
    protocol = "tcp"
    ports    = [var.Port]
  }

  priority  = 1000
  direction = "INGRESS"

  source_ranges = ["0.0.0.0/0", "35.235.240.0/20"]
  target_tags   = ["webapp"]
}