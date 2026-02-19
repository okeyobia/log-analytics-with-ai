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
              set -e
              
              # ------------------------
              # Update system packages
              # ------------------------
              sudo apt-get update
              sudo apt-get upgrade -y
              
              # ------------------------
              # Install Docker 20.10
              # ------------------------
              # Install dependencies
              sudo apt-get install -y ca-certificates curl gnupg lsb-release
              
              # Add Docker GPG key
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
              
              # Add Docker repository
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              
              # Update package index
              sudo apt-get update
              
              # Install Docker 20.10.x
              sudo apt-get install -y docker-ce=5:20.10.* docker-ce-cli=5:20.10.* containerd.io
              
              # Start and enable Docker
              sudo systemctl enable docker
              sudo systemctl start docker
              
              # Add ubuntu user to docker group
              sudo usermod -aG docker ubuntu

              # ------------------------
              # Software installation passed from root module
              # ------------------------
              ${var.software_script}
              EOF

  tags = { Name = var.instance_name }
}
