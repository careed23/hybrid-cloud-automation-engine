variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
  default     = "hcae"
}

variable "cidr" {
  description = "Primary VCN CIDR block"
  type        = string
  default     = "10.20.0.0/16"
}

variable "compartment_ocid" {
  description = "Compartment OCID where resources will be created"
  type        = string
}

variable "region" {
  description = "OCI region"
  type        = string
  default     = "us-ashburn-1"
}

variable "availability_domain" {
  description = "Availability domain to place subnet/instances in (optional). If empty, use first available AD." 
  type        = string
  default     = ""
}

variable "public_subnet_cidr" {
  description = "CIDR for a single public subnet inside the VCN"
  type        = string
  default     = "10.20.1.0/24"
}

variable "public_subnet_security_list_ids" {
  description = "Optional list of security list OCIDs to associate with the public subnet"
  type        = list(string)
  default     = []
}
