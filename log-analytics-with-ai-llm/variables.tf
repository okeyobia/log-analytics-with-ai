variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "key_name" {
  type = string
}

variable "ami_id" {
  type    = string
  default = "ami-0c55b159cbfafe1f0"  # Ubuntu 22.04 LTS in us-east-1
}

variable "allowed_ip" {
  type    = string
  default = "0.0.0.0/0"
}
