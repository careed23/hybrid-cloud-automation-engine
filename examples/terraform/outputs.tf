output "aws_vpc_id" {
  value = module.aws_vpc.vpc_id
}

output "oci_vcn_id" {
  value = module.oci_vcn_with_slist.vcn_id
}

output "aws_instance_id" {
  value = try(aws_instance.example[0].id, "")
}

output "oci_instance_id" {
  value = try(oci_core_instance.example[0].id, "")
}

output "aws_instance_public_ip" {
  value = try(aws_instance.example[0].public_ip, "")
}

output "oci_instance_public_ip" {
  # This may be empty if no OCI instance was created; terraform will return empty string via try()
  value = try(oci_core_instance.example[0].public_ip, "")
}
