variable "key_name" {
  description = "The name of the EC2 key pair."
  type        = string
}

variable "public_subnet_id" {
  description = "The ID of the public subnet for the public instance."
  type        = string
}

variable "private_subnet_id" {
  description = "The ID of the private subnet for the private instance."
  type        = string
}

variable "access_sg_id" {
  description = "The ID of the security group allowing SSH access."
  type        = string
}