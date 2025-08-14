output "quarantine_sg_id" {
  description = "The ID of the quarantine security group."
  value       = aws_security_group.quarantine.id
}

output "normal_access_sg_id" {
  description = "The ID of the normal access security group."
  value       = aws_security_group.normal_access.id
}