# Log Analytics with AI/LLM Infrastructure

A Terraform-based Infrastructure as Code (IaC) project that deploys a complete log analytics platform on AWS with AI/LLM capabilities.

## Overview

This project provisions three AWS EC2 instances running on Ubuntu 22.04 LTS with Docker 20.10, each configured for specific purposes:

- **Rancher Instance**: Container orchestration and management platform
- **Kubernetes Instance**: Lightweight Kubernetes cluster (k3s v1.24.17)
- **Ollama Instance**: Local AI/LLM inference engine

## Architecture

```
AWS VPC (Default)
├── Security Group (ec2-security-group)
│   ├── SSH (22)
│   ├── HTTP (80)
│   └── HTTPS (443)
├── Rancher EC2 (t3.large, 30GB root)
├── Kubernetes EC2 (t3.xlarge, 50GB root)
└── Ollama EC2 (r5.2xlarge, 200GB root)
```

## Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.0
- AWS CLI configured with credentials
- SSH key pair created in your AWS region

## Project Structure

```
log-analytics-with-ai-llm/
├── main.tf                 # Root module with EC2 instances
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── provider.tf             # AWS provider configuration
├── .gitignore              # Git ignore patterns
├── .terraformignore        # Terraform ignore patterns
├── terraform.tfstate       # State file (auto-generated)
├── terraform.tfstate.backup # State backup (auto-generated)
├── .terraform.lock.hcl     # Dependency lock file
└── modules/
    └── ec2_app_instance/   # Reusable EC2 instance module
        ├── main.tf         # EC2 resource definition
        ├── variables.tf    # Module variables
        └── outputs.tf      # Module outputs
```

## Quick Start

### 1. Clone the Repository

```bash
cd /Users/okeyobia/dev/aiops/log-analyzier/log-analytics-with-ai-llm
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Create terraform.tfvars

Create a file named `terraform.tfvars`:

```hcl
key_name   = "your-aws-key-pair-name"
aws_region = "us-east-1"
allowed_ip = "0.0.0.0/0"  # Change to your IP for security
```

### 4. Review the Deployment Plan

```bash
terraform plan
```

### 5. Apply the Configuration

```bash
terraform apply
```

Terraform will prompt for confirmation before creating resources.

## Configuration

### Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `us-east-1` | AWS region for resources |
| `key_name` | string | (required) | SSH key pair name in AWS |
| `allowed_ip` | string | `0.0.0.0/0` | IP CIDR for security group access |

### Customization

Edit `main.tf` to customize instance types:

```hcl
# Change Rancher instance type
instance_type = "t3.xlarge"  # Default: t3.large

# Change volume size
volume_size = 50  # Default: 30 GB
```

## Outputs

After successful deployment, Terraform outputs the public IPs:

```
kubernetes_ip = "203.0.113.45"
ollama_ip     = "203.0.113.46"
rancher_ip    = "203.0.113.47"
```

## Accessing Services

### Rancher
```bash
ssh -i your-key.pem ubuntu@<rancher_ip>
# Access web UI at https://<rancher_ip>
```

### Kubernetes (k3s)
```bash
ssh -i your-key.pem ubuntu@<kubernetes_ip>
```

### Ollama
```bash
ssh -i your-key.pem ubuntu@<ollama_ip>
# Ollama API runs on http://localhost:11434
```

## Troubleshooting

### Check Service Logs

**Rancher:**
```bash
ssh -i your-key.pem ubuntu@<rancher_ip>
sudo docker logs rancher --tail 100
```

**Kubernetes:**
```bash
ssh -i your-key.pem ubuntu@<kubernetes_ip>
sudo systemctl status k3s
sudo journalctl -u k3s -n 50
```

**Ollama:**
```bash
ssh -i your-key.pem ubuntu@<ollama_ip>
sudo systemctl status ollama
```

### Check Installation Logs

Rancher installation details are logged to `/var/log/rancher-install.log`:

```bash
sudo cat /var/log/rancher-install.log
```

### Verify Docker

```bash
sudo docker ps  # List running containers
sudo docker ps -a  # List all containers
sudo docker logs <container_id>  # View container logs
```

## Cleanup

To destroy all resources:

```bash
terraform destroy -var="key_name=your-aws-key-pair-name"
```

Confirm when prompted.

## Security Considerations

⚠️ **Important Security Notes:**

1. **Default Security Group**: The current configuration allows SSH from any IP (`0.0.0.0/0`). Restrict this with:
   ```hcl
   allowed_ip = "YOUR.IP.ADDRESS/32"
   ```

2. **SSH Key Management**: Keep your SSH private key secure and never commit it to version control.

3. **Instance Sizing**: Larger instances provide better performance but cost more. Adjust `instance_type` as needed.

4. **Firewall Rules**: Consider further restricting HTTP/HTTPS access based on your use case.

## State Management

- `terraform.tfstate` - Current infrastructure state (do not edit)
- `terraform.tfstate.backup` - Previous state backup
- `.terraform.lock.hcl` - Provider version lock (commit to git)

For production, store state remotely using:
- AWS S3 + DynamoDB
- Terraform Cloud
- HashiCorp Consul

## Cost Estimation

Approximate monthly costs (us-east-1 on-demand):
- t3.large Rancher: ~$58/month
- t3.xlarge Kubernetes: ~$116/month
- r5.2xlarge Ollama: ~$296/month
- **Total: ~$470/month**

(Costs vary by region and instance type)

## Contributing

When making changes:

1. Test with `terraform plan`
2. Review changes carefully
3. Use meaningful commit messages
4. Keep state files in `.gitignore`

## License

This project is provided as-is for educational and operational purposes.

## Support

For issues related to:
- **Rancher**: Visit [rancher.com](https://www.rancher.com)
- **Kubernetes**: Visit [kubernetes.io](https://kubernetes.io)
- **Ollama**: Visit [ollama.ai](https://ollama.ai)
- **Terraform**: Visit [terraform.io](https://www.terraform.io)

## Changelog

### v1.0.0 (2026-02-18)
- Initial project setup
- Three-instance deployment (Rancher, Kubernetes, Ollama)
- Ubuntu 22.04 LTS base images
- Docker 20.10 installation
- Automated service deployment via user_data scripts
