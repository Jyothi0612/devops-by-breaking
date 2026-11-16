# shellcheck shell=bash
cat > "$DBB_WORK/main.tf" <<'EOF'
terraform {
  required_version = ">= 1.5"
  required_providers {
    random = { source = "hashicorp/random", version = "3.9.1" }
  }
}

locals {
  services = ["api", "worker"]
}

moved {
  from = random_password.service_token[0]
  to   = random_password.service_token["api"]
}

moved {
  from = random_password.service_token[2]
  to   = random_password.service_token["worker"]
}

resource "random_password" "service_token" {
  keepers  = { service = each.key }
  for_each = toset(local.services)
  length   = 24
  special  = false
}

output "api_fingerprint" {
  value = nonsensitive(sha256(random_password.service_token["api"].result))
}

output "worker_fingerprint" {
  value = nonsensitive(sha256(random_password.service_token["worker"].result))
}
EOF
tf apply -auto-approve -input=false -no-color >/dev/null
