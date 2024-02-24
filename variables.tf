variable "credentialsFile" {
  default = "credentials.json"
}

variable "projectId" {
  default = "cloudassignment03-413923"
}

variable "region" {
  default = "us-east1"
}

variable "mode"{
  default = "REGIONAL"
}
variable "zone" {
  default = "us-east1-b"
}

variable "num_vpc" {
  description = "Number of VPCs to create"
  default     = "1"
}

variable "num_webapp_subnets_per_vpc" {
  description = "VPC number to create"
  default     = "1"
}

variable "num_db_subnets_per_vpc" {
  description = " subnets number to create per VPC"
  default     = "1"
}

variable "InOutGress" {
  default = "INGRESS"
}

variable "webapp_cIDR_Range" {
  default = "10.0.1.0/24"
  
}

variable "address_type" {
  default = "EXTERNAL"
  
}

variable "email" {
  default = "csye-gcp-assignment04-sa@cloudassignment03-413923.iam.gserviceaccount.com"
  
}



variable "machineType" {
  default = "n2-standard-2"
}

variable "DB_CIDR_Range" {
  default = "10.0.2.0/24"
  
}

variable "Port" {
  default = "3000"
}

variable "ImagePath" {
  default = "projects/cloudassignment03-413923/global/images/cloud-packer-vm-custom-image"  
}

variable "vmname" {
  default = "gcpvm-instance"
  
}

variable "IPVersion" {
  default = "IPV4"
}

variable "gcpcomputeaddressName" {
  default = "ipaddressforgcp"
  
}

variable "firewallRuleName" {
  default = "vmfirewall"
  
}