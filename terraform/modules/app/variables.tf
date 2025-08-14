variable "subscriber_email" {
  description = "The email address for SNS notifications."
  type        = string
  sensitive   = true
}

variable "quarantine_sg_id" {
  description = "The ID of the quarantine security group."
  type        = string
}

variable "layer_zip_path" {
  description = "The local path to the Lambda Layer zip file."
  type        = string
}

variable "lambda_function_dir" {
  description = "The local path to the Lambda function's source code directory."
  type        = string
}
