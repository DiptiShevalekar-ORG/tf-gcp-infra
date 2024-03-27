provider "google" {
  project     = var.projectId
  region      = var.region
}

# locals {
#   vpc_names = [for i in range(var.num_vpc) : "csye-vpc-${i}"]
# }

resource "google_compute_network" "vpc" {
  name                            = "webapp-vpc-2"
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
  //direction = var.InOutGress

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["webapp"]
}


resource "google_compute_global_address" "private_ip_block" {
  name          = "private-ip-block2"
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
  length           = 16
  special          = false
  //override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_sql_user" "webapp" {
  name     = "webapp"
  instance = google_sql_database_instance.csye6225.name
  password = random_password.password.result
}

//Host = google_sql_database_instance.csye6225.pr


resource "google_dns_record_set" "a_record" {
  name         = "diptishevalekar.online."
  managed_zone = "cloud-dipti-zone"
  type         = "A"
  ttl          = 60
  rrdatas      = [google_compute_instance.instance.network_interface[0].access_config[0].nat_ip]
}

resource "google_service_account" "service_account_iam" {
  account_id   = "logger-sa-assignment06"
  display_name = "logger-sa-assignment06"
}

resource "google_project_iam_binding" "vm_loggingadmin" {
  project = var.projectId
  role    = "roles/logging.admin"
  members = ["serviceAccount:${google_service_account.service_account_iam.email}"]
}

resource "google_project_iam_binding" "vm-opsagent-publisher" {
  project = var.projectId
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${google_service_account.service_account_iam.email}"]
}

resource "google_project_iam_binding" "vm_metricswriter" {
  project = var.projectId
  role    = "roles/monitoring.metricWriter"
  members = ["serviceAccount:${google_service_account.service_account_iam.email}"]
}

resource "google_service_account" "service_account_cloudfunction" {
  account_id   = "logger-sa-assignment07"
  display_name = "logger-sa-assignment07"
  depends_on = [ google_pubsub_topic.verify_email ]
}

resource "google_project_iam_binding" "pubsub-publisher" {
  project = var.projectId
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${google_service_account.service_account_cloudfunction.email}"]
}

resource "google_project_iam_binding" "pubsub-clf-invoker" {
  project = var.projectId
  role    = "roles/cloudfunctions.invoker"
  members = ["serviceAccount:${google_service_account.service_account_cloudfunction.email}"]
}
resource "google_project_iam_binding" "pubsub-clf-client" {
  project = var.projectId
  role    = "roles/cloudsql.client"
  members = ["serviceAccount:${google_service_account.service_account_cloudfunction.email}"]
}

resource "google_project_iam_binding" "pubsub-clf-subs" {
  project = var.projectId
  role    = "roles/pubsub.subscriber"
  members = ["serviceAccount:${google_service_account.service_account_cloudfunction.email}"]
}

resource "google_project_iam_binding" "cloud-function-invoker" {
  project = var.projectId
  role    = "roles/run.invoker"
  members = ["serviceAccount:${google_service_account.service_account_cloudfunction.email}"]
}

resource "google_project_iam_binding" "cloud-vpc-access-user" {
  project = var.projectId
  role    = "roles/vpcaccess.user"
  members = ["serviceAccount:${google_service_account.service_account_cloudfunction.email}"]
}

#setting iam role to service account
# resource "google_project_iam_binding" "project" {
#   project = var.projectId
#   role = "roles/logging.admin"
#   members = [
#     "serviceAccount:service-account-iam-id@csye6225-414121.iam.gserviceaccount.com"
#   ]
# }

resource "google_compute_instance" "instance" {
  name         = var.vmname
  machine_type = var.machineType
  zone         = var.zone
  depends_on   = [google_project_iam_binding.vm_metricswriter]

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
    email  = google_service_account.service_account_iam.email
    scopes = ["cloud-platform", "pubsub"]
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
sudo chown -R csye6225:csye6225 opt/webappUnzipped/Dipti_Shevalekar_002245703_01
sudo chmod -R 755 opt/webappUnzipped/Dipti_Shevalekar_002245703_01
sudo systemctl restart systemdSetup.service


SCRIPT

}

resource "google_vpc_access_connector" "my_connector" {
  name            = "my-vpc-connector"
  network         = google_compute_network.vpc.self_link
  ip_cidr_range   = "10.8.0.0/28"
}


resource "google_pubsub_topic" "verify_email" {
  name                       = "verify_email"
  message_retention_duration = "604800s"
  # message_storage_policy {
  #   allowed_persistence_regions = [var.region]
  # }
}

# resource "google_pubsub_subscription" "verify_email_sub" {
#   name  = "verify-email-sub"
#   topic = google_pubsub_topic.verify_email.name
#   # push_config {
#   #   push_endpoint = "https://your-cloud-function-url"
#   # }
# }

resource "google_cloudfunctions2_function" "verify_email" {
  name        = var.cloud_function_name
  location    = var.region
  description = "Send verification emails"

  build_config {
    runtime     = var.cloud_function_runtime
    entry_point = var.entry_point
    source {
      storage_source {
        bucket = "cloud-csye6225-bucket"
        object = "FORK_serverless.zip"
      }
    }
  }

  service_config {
    max_instance_count    = 1
    min_instance_count    = 1
    available_cpu         = "1"
    available_memory      = var.cloud_function_available_memory_mb
    timeout_seconds       = var.cloud_function_timeout
    service_account_email = google_service_account.service_account_cloudfunction.email
    vpc_connector         = google_vpc_access_connector.my_connector.self_link

    environment_variables = {
      MAILGUN_API_KEY  = var.MAILGUN_API_KEY
      WEBAPP_URL       = var.WEBAPP_URL
      DB_USERNAME=google_sql_user.webapp.name
      DATABASE=google_sql_database.webapp.name
      PASSWORD=random_password.password.result
      HOST=google_sql_database_instance.csye6225.private_ip_address
    }

  }

  event_trigger {
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.verify_email.id
    retry_policy          = "RETRY_POLICY_RETRY"
    trigger_region        = "us-east1"
    service_account_email = google_service_account.service_account_cloudfunction.email
  }

  depends_on = [google_pubsub_topic.verify_email]
}