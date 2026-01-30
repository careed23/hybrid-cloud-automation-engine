# Example variables for the Terraform root that composes AWS and OCI modules.
# Provide provider credentials and image IDs via environment variables or CLI.

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_ami" {
  description = "AMI id to use for the example EC2 instance (set in terraform.tfvars)
  "
  type = string
  default = ""
}

variable "oci_compartment_ocid" {
  type = string
  default = ""
}

variable "oci_image_id" {
  description = "OCI image OCID to use for the example compute instance"
  type = string
  default = ""
}

variable "name_prefix" {
  type = string
  default = "hcae-demo"
}

variable "repo_url" {
  description = "Git repository URL for ansible playbooks (used by cloud-init/ansible-pull)"
  type        = string
  default     = "https://github.com/your-org/hybrid-cloud-automation-engine.git"
}

variable "ssh_key_path" {
  description = "Path where generated SSH keys will be written relative to this module"
  type        = string
  default     = "${path.module}/ssh_key"
}
