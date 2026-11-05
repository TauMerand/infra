# Bootstrap

Step-by-step setup from an empty Cloudflare account to a working remote state bucket. Later stages
(shared resources, cluster, Flux) are listed at the end and will be filled in as they are built.

The layout and apply order are explained in [ADR 0001](adr/0001-terraform-directory-structure.md).

## 1. Prerequisites

Tools on your PATH:

- OpenTofu 1.10 or later (`tofu version`; this repo is developed on 1.13)
- `pre-commit`, `tflint`, `gitleaks` (see the root README)
- `openssl` (to generate the encryption passphrase)

Accounts:

- A Cloudflare account that owns your domain, with **R2 enabled**. R2 may ask for a payment method, even though the
  free tier is ample for state files.

## 2. Gather Cloudflare credentials

### Account ID

In the Cloudflare dashboard, open **R2 Object Storage**. The account ID is shown on the overview page (and in the URL).

### API token for OpenTofu

This token lets the Cloudflare provider create the bucket.

1. Dashboard, **My Profile**, **API Tokens**, **Create Token**, **Create Custom Token**.
1. Permission: **Account** / **Workers R2 Storage** / **Edit**.
1. Account resources: include only your account.
1. Create it and copy the value. It is shown once.

Later stacks that manage DNS will use a separate token scoped to **Zone / DNS / Edit** on your zone only.

## 3. Create the state encryption passphrase

State files contain secrets, so OpenTofu encrypts them before they are written, both locally and in R2
(see `terraform/bootstrap/encryption.tf`). The passphrase is never committed.

```sh
openssl rand -base64 32
```

Store the result in your password manager. **If you lose it, you lose access to every encrypted state file.** There is
no recovery. The same passphrase is used by all stacks in this repo.

## 4. Set the environment

Export these in the shell you will run `tofu` from. Do not write them to any file in the repo.

```sh
export CLOUDFLARE_API_TOKEN='<token from step 2>'
export TF_ENCRYPTION='key_provider "pbkdf2" "main" { passphrase = "<passphrase from step 3>" }'
```

Tips:

- Prefix the commands with a space (if `HISTCONTROL=ignorespace` is set), or load the values from your password manager's
  CLI, so they don't land in shell history.
- If you use direnv, a `.envrc` is already gitignored. Keep secrets out of it and read them from the password manager instead.

## 5. Configure variables

```sh
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` (gitignored):

- `account_id`: from step 2.
- `bucket_name`: choose a specific name, for example `<yourname>-tfstate`.
- `location`: optional. The default `weur` suits a Hetzner server in Germany or Finland.

## 6. Apply

```sh
tofu init
tofu plan
tofu apply
```

Check that `plan` shows exactly one resource: `cloudflare_r2_bucket.tfstate`. This stack uses **local state**, written to
`terraform/bootstrap/terraform.tfstate`.

Verify the state is encrypted:

```sh
head -c 300 terraform.tfstate
```

You should see JSON containing `"encrypted_data"` and `"encryption_version"`, not readable resource attributes.
If you see plaintext, stop and check that `TF_ENCRYPTION` is set.

Back up `terraform.tfstate` (it is encrypted, so a private cloud folder or password manager attachment is fine).
If it is lost, the bucket can be re-adopted with `tofu import`.

## 7. Create S3 credentials for the backend

The Cloudflare provider cannot create the S3-style keys that backends need, so do this once in the dashboard:

1. **R2 Object Storage**, **Manage API Tokens**, **Create API token**.
1. Permission: **Object Read & Write**. Restrict it to the state bucket only.
1. Copy the **Access Key ID** and **Secret Access Key** (shown once) and store them in your password manager.

Export them whenever you work on a stack that uses the remote backend:

```sh
export AWS_ACCESS_KEY_ID='<access key id>'
export AWS_SECRET_ACCESS_KEY='<secret access key>'
```

(The `AWS_` names are only because the backend speaks the S3 protocol. This is not AWS.)

## 8. Use the bucket from other stacks

In each other stack (for example `terraform/shared/cloudflare`):

1. Copy `terraform/bootstrap/backend.tf.example` to `backend.tf` in that stack.
1. Set `bucket` to your bucket name, replace `<account_id>` in the endpoint, and give the stack a unique `key`
   such as `shared/cloudflare/terraform.tfstate`.
1. Copy `terraform/bootstrap/encryption.tf` into the stack as well. Every stack must have the same `encryption` block and
   the same `TF_ENCRYPTION` passphrase.
1. Run `tofu init`.

If one stack reads another through `terraform_remote_state`, that data source needs the encryption settings too. Prefer
passing values through variables or data sources where you can.

## 9. Optional: move bootstrap's own state into the bucket

Not required. If you want it, add a `backend.tf` to `terraform/bootstrap` as in step 8 with
`key = "bootstrap/terraform.tfstate"`, then run `tofu init -migrate-state`. Keep a backup of the local state first.
Downside: if the bucket is ever damaged, the stack that could rebuild it has lost its state.

## Rotating the passphrase

OpenTofu supports migrating between keys using a `fallback` block. The outline is: add a second key provider with the new
passphrase, set the old method as `fallback`, run `tofu apply` in every stack, then remove the fallback. Do this
for all stacks, and keep a backup of every state file before you start. Details: the OpenTofu state encryption docs.

## Later stages (to be written)

1. Shared resources (`terraform/shared/cloudflare`, `terraform/shared/github`)
1. Provisioning the cluster (`terraform/envs/prod/cluster`)
1. Getting the kubeconfig
1. Bootstrapping Flux
1. Application infrastructure (`terraform/envs/prod/webapp`)
1. Tearing down and rebuilding
