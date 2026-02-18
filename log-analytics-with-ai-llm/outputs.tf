output "rancher_ip" {
  value = module.rancher.public_ip
}

output "kubernetes_ip" {
  value = module.kubernetes.public_ip
}

output "ollama_ip" {
  value = module.ollama.public_ip
}
