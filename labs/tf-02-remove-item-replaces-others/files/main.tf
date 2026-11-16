terraform {
  required_version = ">= 1.5"
  required_providers {
    random = { source = "hashicorp/random", version = "3.9.1" }
  }
}

locals {
  services = ["api", "worker"]
}

resource "random_password" "service_token" {
  keepers = { service = local.services[count.index] }
  count   = length(local.services)
  length  = 24
  special = false
}

output "api_fingerprint" {
  value = nonsensitive(sha256(random_password.service_token[0].result))
}

output "worker_fingerprint" {
  value = nonsensitive(sha256(random_password.service_token[1].result))
}
