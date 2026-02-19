data "aws_vpc" "default" {
  default = true
}

# Find latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
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
  ami_id              = data.aws_ami.ubuntu.id
  instance_type       = "t3.large"
  instance_name       = "Rancher-Instance"
  key_name            = var.key_name
  security_group_id   = aws_security_group.ec2_sg.id
  volume_size         = 30
  software_script     = <<-EOR
                        #!/bin/bash
                        set -e
                        
                        LOGFILE="/var/log/rancher-install.log"
                        {
                          echo "=== Rancher Installation Started at $(date) ==="
                          
                          # Ensure Docker socket is properly set up
                          sudo usermod -aG docker ubuntu || true
                          
                          # Wait longer for Docker daemon
                          echo "Waiting for Docker daemon to be ready..."
                          MAX_WAIT=120
                          ELAPSED=0
                          while ! sudo docker ps > /dev/null 2>&1; do
                            if [ $ELAPSED -ge $MAX_WAIT ]; then
                              echo "TIMEOUT: Docker daemon failed to start"
                              sudo systemctl status docker
                              exit 1
                            fi
                            echo "Docker not ready, waiting... ($ELAPSED/$MAX_WAIT seconds)"
                            sleep 3
                            ELAPSED=$((ELAPSED + 3))
                          done
                          
                          echo "Docker daemon is ready!"
                          sudo docker version
                          
                          # Pull image with retries
                          echo "Pulling Rancher image..."
                          PULL_RETRIES=0
                          MAX_PULL_RETRIES=5
                          while [ $PULL_RETRIES -lt $MAX_PULL_RETRIES ]; do
                            if sudo docker pull rancher/rancher:latest; then
                              echo "Successfully pulled Rancher image"
                              break
                            fi
                            PULL_RETRIES=$((PULL_RETRIES + 1))
                            echo "Docker pull failed, retrying... ($PULL_RETRIES/$MAX_PULL_RETRIES)"
                            sleep 10
                          done
                          
                          if [ $PULL_RETRIES -ge $MAX_PULL_RETRIES ]; then
                            echo "FAILED: Could not pull Rancher image after $MAX_PULL_RETRIES attempts"
                            exit 1
                          fi
                          
                          # Start Rancher container with proper resources
                          echo "Starting Rancher container..."
                          sudo docker run -d \
                            --privileged \
                            --restart=unless-stopped \
                            --memory=2g \
                            --memory-reservation=1g \
                            -p 80:80 \
                            -p 443:443 \
                            -v rancher-data:/var/lib/rancher \
                            --name rancher \
                            rancher/rancher:latest
                          
                          echo "Waiting for container to start..."
                          sleep 5
                          
                          # Verify container is running
                          if sudo docker ps | grep rancher; then
                            echo "=== Rancher Started Successfully ==="
                          else
                            echo "ERROR: Rancher container failed to start"
                            sudo docker logs rancher 2>&1 || true
                            exit 1
                          fi
                        } >> "$LOGFILE" 2>&1
                        EOR
}

module "kubernetes" {
  source              = "./modules/ec2_app_instance"
  ami_id              = data.aws_ami.ubuntu.id
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
  ami_id              = data.aws_ami.ubuntu.id
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
