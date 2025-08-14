output "public_instance_ip" {
  description = "The public IP address of the EC2 instance in the public subnet."
  value       = module.compute.public_instance_ip
}

output "ssh_command" {
  description = "The command to SSH into the public EC2 instance."
  value       = "ssh -i ${var.key_name}.pem ec2-user@${module.compute.public_instance_ip}"
}