# tf-01 · Renamed a resource, plan wants to destroy the database password

Terraform · Level 1 · about 15 min · Maps to: Terraform Associate (manage state, refactor configuration)

## The ticket

> **PR #482 "naming clean-up" — CI plan is red**
>
> A teammate renamed `random_password.db` to `random_password.orders_db` so the code
> reads better. No values were changed. The plan in CI now says:
>
> `Plan: 1 to add, 1 to change, 1 to destroy.`
>
> That password belongs to the production orders database and every service has it.
> The team still wants the new name. **Make the plan a no-op without changing the
> password.** Your files are in `workspace/tf-01/`.

## What you see

```
$ terraform plan

  # random_password.db will be destroyed
  # (because random_password.db is not in configuration)
  - resource "random_password" "db" {
      ...
    }

  # random_password.orders_db will be created
  + resource "random_password" "orders_db" {
      + id          = (known after apply)
      + length      = 24
      + result      = (sensitive value)
      ...
    }

  # terraform_data.orders_database will be updated in-place
  ~ resource "terraform_data" "orders_database" {
      ~ input  = {
            name                 = "orders-prod"
          ~ password_fingerprint = (sensitive value)
        }
    }

Plan: 1 to add, 1 to change, 1 to destroy.
```

## Your goal

`./dbb check` verifies each of these:

- [ ] `terraform plan` reports no changes
- [ ] The new name is kept: `random_password.orders_db` is in the state
- [ ] The old name is gone from the configuration
- [ ] The production password is unchanged

Run Terraform with `./dbb shell` (then `terraform plan`), or one command at a time:
`./dbb exec -- terraform plan`. Edit `workspace/tf-01/main.tf` with your own editor.

## Predict first

Only a name changed, not a single value. Why does Terraform think a resource was deleted
and another one created? What does Terraform use to decide that a block in your code and
an object in the real world are the same thing?

## Skills you'll practise

Resource addresses · reading a plan before applying · `moved` blocks · `terraform state mv` · `terraform state list`
