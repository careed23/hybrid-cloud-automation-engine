variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
  default     = "hcae"
}

variable "cidr" {
  description = "Primary VPC CIDR block"
  type        = string
  default     = "10.10.0.0/16"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "public_subnets" {
  description = "List of public subnets to create"
  type        = list(string)
  default     = ["10.10.1.0/24"]
}
