variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "key_name" {
  type = string
}

variable "ami_id" {
  type    = string
  default = "ami-0c02fb55956c7d316"
}

variable "allowed_ip" {
  type    = string
  default = "0.0.0.0/0"
}
