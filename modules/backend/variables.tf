variable "ami" {
  description = "AMI ID for EC2"
}

variable "instance_type" {
  description = "EC2 instance for e3"
  default     = "t2.micro"
}