variable "credentialsFile" {
  default = "credentials.json"
}

variable "projectId" {
  default = "cloudassignment03-413923"
}

variable "region" {
  default = "us-east1"
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