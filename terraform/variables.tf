variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "subscriber_email" {
  description = "The email address to subscribe to the SNS topic."
  type        = string
  sensitive   = true
}

variable "key_name" {
  description = "The name of the EC2 key pair for SSH access."
  type        = string
  default     = "cloud-warden-key"
}

variable "layer_zip_path" {
  description = "The local path to the aws-reflex Lambda Layer zip file."
  type        = string
  default     = "../layers/aws_reflex_layer.zip"
}

variable "lambda_function_dir" {
  description = "The local path to the Lambda function's source code directory."
  type        = string
  default     = "../lambda_code"
}