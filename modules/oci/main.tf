terraform {
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "~> 4.0"
    }
  }
}

provider "oci" {
  region = var.region
}

resource "oci_core_virtual_network" "this" {
  compartment_id = var.compartment_ocid
  display_name   = var.name_prefix
  cidr_block     = var.cidr
}

# Create a single public subnet for examples and instance placement
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

resource "oci_core_subnet" "public" {
  compartment_id     = var.compartment_ocid
  vcn_id             = oci_core_virtual_network.this.id
  display_name       = "${var.name_prefix}-public-subnet"
  cidr_block         = var.public_subnet_cidr
  availability_domain = var.availability_domain != "" ? var.availability_domain : data.oci_identity_availability_domains.ads.availability_domains[0].name
  # Associate security lists if provided (example roots can pass a security list OCID to open ports)
  security_list_ids  = length(var.public_subnet_security_list_ids) > 0 ? var.public_subnet_security_list_ids : null
  # Keep subnet public by not associating a route table that blocks egress; in real modules, expose route table options
}
