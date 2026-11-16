# tf-01 · Solution

## Root cause

Terraform identifies a resource by its **address** (`random_password.db`), not by its
contents. The state file maps each address to a real object. When the address in the
code changed, Terraform found:

- an address in the state with no block in the code → destroy it
- a block in the code with no entry in the state → create it

Nothing in a plain rename tells Terraform these are the same object. You have to say so.

## How to find it

```
# 1. Read the plan. Never skim the last line only.
terraform plan
  # random_password.db will be destroyed
  # (because random_password.db is not in configuration)
  # random_password.orders_db will be created
Plan: 1 to add, 1 to change, 1 to destroy.

# 2. Compare what the state knows with what the code says
terraform state list
random_password.db
terraform_data.orders_database

grep 'resource "random_password"' main.tf
resource "random_password" "orders_db" {
```

"X will be destroyed because X is not in configuration" right next to "Y will be
created", same type, same arguments: that is the signature of a rename.

## Fix

Add a `moved` block next to the resource, then plan and apply:

```hcl
moved {
  from = random_password.db
  to   = random_password.orders_db
}
```

```
terraform plan     # "random_password.db has moved to random_password.orders_db" — 0 to add, 0 to destroy
terraform apply    # records the move in the state
```

The other valid fix edits the state directly:

```
terraform state mv random_password.db random_password.orders_db
```

Prefer `moved`. It is code: it goes through review, it runs the same way in every
environment and for every teammate, and the plan shows it before anything changes.
`state mv` is a manual step someone must remember to run on every workspace.

## Why the obvious fix is wrong

- **"It's only a rename, just apply":** Terraform does exactly what the plan said. The
  password is destroyed and a new one generated. Every service holding the old one fails
  to authenticate. This is how a refactor becomes an outage.
- **Rename it back:** the plan is clean, and the team does not get the change it asked
  for. It also teaches everyone that renames are dangerous, so the code never gets tidied.

## Prevention

Stop destructive plans from merging unnoticed. In CI, fail when a plan deletes anything
unless the pull request is labelled as intentional:

```
terraform plan -out=tfplan
terraform show -json tfplan \
  | jq -e '[.resource_changes[] | select(.change.actions | index("delete"))] | length == 0' \
  || { echo "This plan destroys resources. Add the 'allow-destroy' label if that is intended."; exit 1; }
```

And put a guard on things that must never be recreated:

```hcl
resource "random_password" "orders_db" {
  length  = 24
  special = false

  lifecycle {
    prevent_destroy = true
  }
}
```

`prevent_destroy` rejects destruction while the protected resource block remains
in configuration. It does **not** protect the old address when that block is removed
or renamed. Adding it to `orders_db` alone will not stop destruction of the old `db`
resource in this lab. Use a `moved` block or `state mv` for the rename, and review
all planned deletions.

See the [lifecycle reference](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#prevent_destroy).

## In production this looks like

- Renaming an `aws_db_instance` or `aws_s3_bucket` block: the plan offers to destroy the
  database or the bucket.
- Moving resources into a module (`aws_instance.web` → `module.web.aws_instance.this`):
  the same problem at a larger scale, and the same `moved` block solves it.
- Switching a resource from `count` to `for_each`: every address changes
  (`[0]` → `["name"]`), so everything is planned for replacement.

## Say it in an interview

*AI-drafted practice answer — review and adapt to your own understanding.*

“I'd compare the planned resource addresses with state. Terraform sees this rename as a
deletion and a creation unless the move is declared. I'd add a moved block, confirm
there's no replacement, and apply it. prevent_destroy isn't a substitute: it can't
protect the old address once its configuration has been removed.”

## Further reading

- Terraform docs: Refactoring — `moved` blocks
- Terraform docs: `terraform state mv`
- Terraform docs: The `lifecycle` meta-argument — `prevent_destroy`
- Terraform docs: `terraform show -json` and the plan JSON format
