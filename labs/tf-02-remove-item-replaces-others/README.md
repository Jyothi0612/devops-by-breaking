# tf-02 · Removed one list item, plan replaces the others

Terraform · Level 2 · about 20 min · Maps to: Terraform Associate (manage resource lifecycle)

## The ticket

> **PR Review — prod-tokens — retiring `billing` rotates `worker`'s token**
>
> We retired the `billing` service and removed `"billing"` from `local.services` in
> `main.tf`. `terraform plan` says `worker_fingerprint` will change. Rotating the
> `worker` token in production will break running workers.

## What you see

Captured from the broken lab; generated values and timestamps vary.

```text
$ terraform plan -no-color
random_password.service_token[0]: Refreshing state... [id=none]
random_password.service_token[1]: Refreshing state... [id=none]
random_password.service_token[2]: Refreshing state... [id=none]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  - destroy
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # random_password.service_token[1] must be replaced
-/+ resource "random_password" "service_token" {
      ~ bcrypt_hash = (sensitive value)
      ~ id          = "none" -> (known after apply)
      ~ keepers     = { # forces replacement
          ~ "service" = "billing" -> "worker"
        }
      ~ result      = (sensitive value)
        # (10 unchanged attributes hidden)
    }

  # random_password.service_token[2] will be destroyed
  # (because index [2] is out of range for count)
  - resource "random_password" "service_token" {
      - bcrypt_hash = (sensitive value) -> null
      - id          = "none" -> null
      - keepers     = {
          - "service" = "worker"
        } -> null
      - length      = 24 -> null
      - lower       = true -> null
      - min_lower   = 0 -> null
      - min_numeric = 0 -> null
      - min_special = 0 -> null
      - min_upper   = 0 -> null
      - number      = true -> null
      - numeric     = true -> null
      - result      = (sensitive value) -> null
      - special     = false -> null
      - upper       = true -> null
    }

Plan: 1 to add, 0 to change, 2 to destroy.

Changes to Outputs:
  ~ worker_fingerprint = "3a6480e359c360c506974d8e9c473115760671d94ae9b3deaa0ba909a6af9dc4" -> (known after apply)

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

## Your goal

`./dbb check` verifies each of these:

- [ ] `terraform plan` reports no pending changes
- [ ] Only two service tokens remain tracked in state
- [ ] `api` and `worker` tokens are unchanged (same fingerprints as before)

## Predict first

Before you type anything: only `"billing"` was removed from `["api", "billing", "worker"]`.
Why did `worker_fingerprint` change in the plan?

## Skills you'll practise

`count` index shift · `for_each` with `toset` · `moved` blocks · `terraform state list` · zero-downtime state refactoring
