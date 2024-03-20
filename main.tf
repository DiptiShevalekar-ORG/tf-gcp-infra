provider "google" {
  credentials = file(var.credentialsFile)
  project     = var.projectId
  region      = var.region
}

# locals {
#   vpc_names = [for i in range(var.num_vpc) : "csye-vpc-${i}"]
# }

resource "google_compute_network" "vpc" {

  name                            = "webapp-vpc"
  auto_create_subnetworks         = false
  routing_mode                    = var.mode
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
  name             = "webapp-route"
  network          = google_compute_network.vpc.self_link
  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
  tags             = ["webapp"]
}

# resource "google_compute_address" "gcpcomputeaddress" {
#   project = var.projectId
#   name = var.gcpcomputeaddressName
#   address_type =  var.address_type
#   ip_version = var.IPVersion
# }



resource "google_compute_firewall" "vmfirewallrule" {

  name    = var.firewallRuleName
  network = google_compute_network.vpc.self_link
  allow {
    protocol = "tcp"
    ports    = [var.Port]
  }

  priority  = 1000
  direction = var.InOutGress

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["webapp"]
}


resource "google_compute_global_address" "private_ip_block" {
  name          = "private-ip-block"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  ip_version    = var.IPVersion
  prefix_length = 20
  network       = google_compute_network.vpc.self_link
}


resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_block.name]
}

resource "google_sql_database_instance" "csye6225" {
  name             = "csye6225"
  region           = var.region
  database_version = "MYSQL_8_0"
  depends_on       = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = "db-f1-micro"
    availability_type = var.mode
    disk_type         = "pd-ssd"
    disk_size         = 100
    backup_configuration {
      enabled            = true
      binary_log_enabled = true
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.self_link
      //enable_private_path_for_google_cloud_services = true
    }

  }
  deletion_protection = false

}

resource "google_sql_database" "webapp" {
  name     = "webapp"
  instance = google_sql_database_instance.csye6225.name
}

resource "random_password" "password" {
  length  = 16
  special = true
 // override_special = "!#$%&*()-_=+[]{}<>:?"
}


resource "google_sql_user" "webapp" {
  name     = "webapp"
  instance = google_sql_database_instance.csye6225.name
  password = random_password.password.result
}

//Host = google_sql_database_instance.csye6225.pr


resource "google_compute_instance" "instance" {
  name         = var.vmname
  machine_type = var.machineType
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
      // nat_ip = google_compute_address.gcpcomputeaddress.address
      //
    }
  }

  service_account {
    email  = var.email
    scopes = ["cloud-platform"]
  }

  tags = ["webapp"]

  metadata_startup_script = <<-SCRIPT
#!/bin/bash

sudo bash -c 'cat <<EOF > /opt/webappUnzipped/Dipti_Shevalekar_002245703_01/.env
DB_USERNAME=${google_sql_user.webapp.name}
DATABASE=${google_sql_database.webapp.name}
PASSWORD=${random_password.password.result}
HOST=${google_sql_database_instance.csye6225.private_ip_address}
PORT=3000
EOF'
sudo chown -R csye6225:csye6225 /opt/webappUnzipped/Dipti_Shevalekar_002245703_01
sudo chmod -R 755 /opt/webappUnzipped/Dipti_Shevalekar_002245703_01
sudo systemctl daemon-reload
sudo systemctl enable systemdSetup.service
sudo systemctl start systemdSetup.service
cd /opt/webappUnzipped/Dipti_Shevalekar_002245703_01/
node server.js

SCRIPT

}

