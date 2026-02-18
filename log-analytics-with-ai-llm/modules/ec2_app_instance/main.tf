resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.security_group_id]

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp2"
  }

  user_data = <<-EOF
              #!/bin/bash
              # ------------------------
              # Install specific Docker 26.1.4
              # ------------------------
              sudo yum update -y
              sudo amazon-linux-extras enable docker
              sudo yum install -y docker-26.1.4
              sudo systemctl enable docker
              sudo systemctl start docker

              # ------------------------
              # Software installation passed from root module
              # ------------------------
              ${var.software_script}
              EOF

  tags = { Name = var.instance_name }
}
