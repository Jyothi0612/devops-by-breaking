terraform {
  required_version = ">= 1.5"
  required_providers {
    random = { source = "hashicorp/random", version = "3.9.1" }
  }
}

# The production orders database password. Created once, 14 months ago.
# Every running service has this value. Recreating it means an outage.
resource "random_password" "orders_db" {
  length  = 24
  special = false
}

# Stand-in for "the thing that consumes the password" (a DB instance, a secret, ...).
resource "terraform_data" "orders_database" {
  input = {
    name                 = "orders-prod"
    password_fingerprint = sha256(random_password.orders_db.result)
  }
}

output "password_fingerprint" {
  value = nonsensitive(sha256(random_password.orders_db.result))
}
