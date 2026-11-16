# tf-02 · Solution

## Root cause

`random_password.service_token` uses `count = length(local.services)`, which keys
instances by integer position (`[0]`, `[1]`, `[2]`). Removing `"billing"` (index `1`)
shifted `"worker"` from `[2]` to `[1]`. The password resource's `keepers.service`
changes from billing to worker at index 1, forcing a replacement. Index 2, which
holds the original worker password, is now outside the count range and would be
destroyed. Only the billing service was meant to be retired.

## How to find it

Run `terraform plan` and `terraform state list` in the workspace:

```sh
terraform plan -no-color
terraform state list
```

The captured plan in `captures/symptom.txt` shows `random_password.service_token[2]`
being destroyed, index 1 being replaced, and the worker fingerprint becoming unknown
until apply. The plan proposes one addition and two destructions.

## Fix

Switch `random_password.service_token` from `count` to `for_each = toset(local.services)`,
add `moved` blocks to map the surviving instances by key, and apply so only the retired
`billing` instance (`[1]`) is destroyed:

```hcl
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
```

Then run `terraform apply -auto-approve` and `./dbb check`.

## Why the obvious fix is wrong

- `keep-billing`: leaving `"billing"` in `local.services` keeps the plan empty, but
  fails to retire the removed service.
- `ignore-and-apply`: running `terraform apply` without migrating off `count`
  destroys `worker`'s real token and generates a replacement at index 1.

## Prevention

Use `for_each` (keyed by stable names or IDs) instead of `count` for any collection
where individual items can be added or removed, and enforce `moved` / plan reviews in
CI for unexpected replacements or output changes.

## In production this looks like

Removing an entry from a `count`-indexed list of subnets, IAM users, or RDS instances
causes Terraform to destroy and recreate every subsequent resource in the list.

## Say it in an interview

*AI-drafted practice answer — review and adapt to your own understanding.*

“I'd inspect which instances the plan wants to replace. With count, removing the middle
list item shifts the later indices; here that changes the token's keeper and forces
replacement. I'd use stable for_each keys and move the surviving state addresses, then
confirm only the retired service is destroyed.”

## Further reading

- [Terraform: Refactoring — moved blocks](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring)
- [Terraform: The for_each meta-argument](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each)
