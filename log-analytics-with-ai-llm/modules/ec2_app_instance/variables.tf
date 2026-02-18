variable "ami_id" {
  type        = string
  description = "AMI ID for EC2 instance"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "instance_name" {
  type        = string
  description = "Name tag for EC2"
}

variable "key_name" {
  type        = string
  description = "Key pair for SSH"
}

variable "security_group_id" {
  type        = string
  description = "Security group ID to attach"
}

variable "volume_size" {
  type        = number
  description = "Root volume size in GB"
}

variable "software_script" {
  type        = string
  description = "Shell commands to install software"
}
