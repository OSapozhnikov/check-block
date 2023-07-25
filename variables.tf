variable "aws_key_name" {
  description = "Key Pair"
  type        = string
  default     = "temabit"
}

variable "app_instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.micro"
}
