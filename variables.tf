variable "credentialsFile" {
  default = "terraformCreds.json"
}

variable "projectId" {
  type = string
}

variable "region" {
  type = string
}

variable "database-name" {
  type = string

}
variable "cloud_function_name" {
  type = string
  
}

variable "entry_point" {
 type = string
}

variable "MAILGUN_API_KEY" {
  type = string
}

variable "cloud_function_timeout" {
  type = number
}
variable "cloud_function_available_memory_mb" {
  type = string
}

variable "WEBAPP_URL" {
  type = string
}

variable "cloud_function_runtime" {
  type = string
}


variable "mode" {
  type = string
}
variable "zone" {
  type = string
}

variable "InOutGress" {
  type = string
}

variable "webapp_cIDR_Range" {
  type = string

}

variable "address_type" {
  type = string

}

variable "email" {
  type = string

}



variable "machineType" {
  type = string
}

variable "DB_CIDR_Range" {
  type = string

}

variable "Port" {
  type = string
}

variable "ImagePath" {
  type = string
}

variable "vmname" {
  type = string

}

variable "IPVersion" {
  type = string
}

variable "gcpcomputeaddressName" {
  type = string

}

variable "firewallRuleName" {
  type = string

}


