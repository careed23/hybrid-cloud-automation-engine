terraform {
  required_version = ">= 1.0"
}

# NOTE: This example root shows how to call the modules in this repo.
# It intentionally leaves provider credentials and AMI/image selection to the user.

provider "aws" {
  region = var.aws_region
}

provider "oci" {
  # Configure OCI provider via environment variables or shared config file
}
terraform {
  required_providers = {
    aws = { source = "hashicorp/aws" }
    oci = { source = "hashicorp/oci" }
    tls = { source = "hashicorp/tls" }
    local = { source = "hashicorp/local" }
  }
}

module "aws_vpc" {
  source      = "../../modules/aws"
  name_prefix = var.name_prefix
  cidr        = "10.10.0.0/16"
  public_subnets = ["10.10.1.0/24"]
  region      = var.aws_region
}

# Generate an SSH keypair for demo purposes (TLS provider).
resource "tls_private_key" "deployer" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.deployer.private_key_pem
  filename        = var.ssh_key_path
  file_permission = "0600"
}

resource "local_file" "public_key" {
  content         = tls_private_key.deployer.public_key_openssh
  filename        = "${var.ssh_key_path}.pub"
  file_permission = "0644"
}

# Create an AWS key pair using the generated public key
resource "aws_key_pair" "deployer" {
  key_name   = "${var.name_prefix}-key"
  public_key = tls_private_key.deployer.public_key_openssh
}

# AWS security group to allow SSH and WireGuard UDP
resource "aws_security_group" "vpn" {
  name        = "${var.name_prefix}-sg"
  description = "Allow SSH and WireGuard"
  vpc_id      = module.aws_vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "example" {
  count         = var.aws_ami != "" ? 1 : 1
  ami           = var.aws_ami != "" ? var.aws_ami : data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = module.aws_vpc.public_subnet_ids[0]
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.vpn.id]

  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y python3 python3-apt git
    apt-get install -y ansible || true
    cd /tmp
    if [ -d /tmp/hcae ]; then rm -rf /tmp/hcae; fi
    git clone "${var.repo_url}" /tmp/hcae || exit 0
    if [ -f /tmp/hcae/ansible/site.yml ]; then
      ansible-pull -U "${var.repo_url}" -d /tmp/hcae -i localhost, site.yml || true
    fi
  EOF

  tags = {
    Name = "${var.name_prefix}-aws"
  }
}

# OCI: create a security list to allow SSH and WireGuard, and attach it to the subnet via module variable override
resource "oci_core_security_list" "vpn" {
  compartment_id = var.oci_compartment_ocid
  vcn_id         = module.oci_vcn.vcn_id
  display_name   = "${var.name_prefix}-vpn-slist"

  ingress_security_rules {
    protocol = "6"
    source = "0.0.0.0/0"
    tcp_options {
      max = 22
      min = 22
    }
  }

  ingress_security_rules {
    protocol = "17"
    source = "0.0.0.0/0"
    udp_options {
      max = 51820
      min = 51820
    }
  }

  egress_security_rules {
    protocol = "all"
    destination = "0.0.0.0/0"
  }
}

# Re-create the OCI module so that the public subnet is associated with the security list we created
module "oci_vcn_with_slist" {
  source           = "../../modules/oci"
  name_prefix      = var.name_prefix
  cidr             = "10.20.0.0/16"
  compartment_ocid = var.oci_compartment_ocid
  region           = "us-ashburn-1"
  public_subnet_cidr = "10.20.1.0/24"
  public_subnet_security_list_ids = [oci_core_security_list.vpn.id]
}

# OCI compute instance (optional)
resource "oci_core_instance" "example" {
  count           = var.oci_image_id != "" ? 1 : 0
  compartment_id  = var.oci_compartment_ocid
  availability_domain = var.oci_availability_domain != "" ? var.oci_availability_domain : null
  shape           = "VM.Standard.E2.1.Micro"
  display_name    = "${var.name_prefix}-oci"
  source_details {
    source_type = "image"
    image_id    = var.oci_image_id
  }

  # Place into the subnet that module created
  create_vnic_details {
    subnet_id = module.oci_vcn_with_slist.public_subnet_id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = tls_private_key.deployer.public_key_openssh
    user_data = base64encode(<<-EOC
      #!/bin/bash
      set -e
      apt-get update
      apt-get install -y python3 python3-apt git
      apt-get install -y ansible || true
      git clone "${var.repo_url}" /tmp/hcae || exit 0
      if [ -f /tmp/hcae/ansible/site.yml ]; then
        ansible-pull -U "${var.repo_url}" -d /tmp/hcae -i localhost, site.yml || true
      fi
    EOC
    )
  }
}
