output "vcn_id" {
  value = oci_core_virtual_network.this.id
}

output "vcn_cidr" {
  value = oci_core_virtual_network.this.cidr_block
}

output "public_subnet_id" {
  value = oci_core_subnet.public.id
}
