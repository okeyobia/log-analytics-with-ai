data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Allow SSH, HTTP, HTTPS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "rancher" {
  source              = "./modules/ec2_app_instance"
  ami_id              = var.ami_id
  instance_type       = "t3.large"
  instance_name       = "Rancher-Instance"
  key_name            = var.key_name
  security_group_id   = aws_security_group.ec2_sg.id
  volume_size         = 30
  software_script     = <<-EOR
                        sudo docker run -d --restart=unless-stopped \
                        -p 80:80 -p 443:443 \
                        rancher/rancher:2.6.9
                        EOR
}

module "kubernetes" {
  source              = "./modules/ec2_app_instance"
  ami_id              = var.ami_id
  instance_type       = "t3.xlarge"
  instance_name       = "Kubernetes-Instance"
  key_name            = var.key_name
  security_group_id   = aws_security_group.ec2_sg.id
  volume_size         = 50
  software_script     = <<-EOK
                        curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.24.17+k3s1 sh -
                        sudo systemctl enable k3s
                        sudo systemctl start k3s
                        EOK
}

module "ollama" {
  source              = "./modules/ec2_app_instance"
  ami_id              = var.ami_id
  instance_type       = "r5.2xlarge"
  instance_name       = "Ollama-Instance"
  key_name            = var.key_name
  security_group_id   = aws_security_group.ec2_sg.id
  volume_size         = 200
  software_script     = <<-EOO
                        # Ollama install (latest official installer)
                        curl -sSL https://ollama.com/install.sh | bash
                        EOO
}
