# 1. Terraform directory structure

- Status: Accepted
- Date: 2026-11-05

## Context

This repo manages a Hetzner k3s cluster and Cloudflare DNS with OpenTofu, plus GitOps via Flux.
We need a layout that:

- keeps blast radius small (a change to DNS must not be able to touch the server),
- supports adding environments later without restructuring,
- avoids chicken-and-egg problems with remote state,
- keeps reusable logic separate from what actually gets applied.

## Decision

Use the following layout. Every directory that contains `.tf` files and is applied is a **root module with its own state**.
Nothing is applied from `terraform/` itself.

```
terraform/
├── modules/          # reusable, never applied directly
├── bootstrap/        # state bucket; local state; applied once by hand
├── shared/           # exists once, environments build on it
│   ├── cloudflare/
│   └── github/
└── envs/
    └── prod/
        ├── cluster/
        └── webapp/
```

### Directories

#### `modules/`

Reusable building blocks, such as a Hetzner k3s server, a firewall, or a set of DNS records.

- Never applied directly. Modules have no `provider` configuration or backend; root modules call them and supply providers.
- Declare provider version constraints (`required_providers`) but not provider blocks.
- Keep inputs and outputs small and documented.
- Don't extract a module until a second place needs it, or until a root module becomes hard to read.

#### `bootstrap/`

Creates the Cloudflare R2 bucket that holds remote state for every other stack.

- Uses **local state**, because the bucket can't store its own state before it exists.
- Applied once, by hand. It rarely changes afterwards.
- The state file is gitignored. It is small but sensitive: back it up. If lost, import the bucket rather than recreating it.
- Needs an R2-capable Cloudflare token and the account ID, from environment variables.

#### `shared/`

Resources that exist once and that every environment builds on. Each subdirectory is its own root module.

- `shared/cloudflare`: the zone and records not tied to one environment (MX, SPF, DKIM, DMARC), plus zone settings.
  Import existing records instead of recreating them. Token scope: DNS edit on this zone only.
- `shared/github`: repository settings, branch protection, and Actions secrets/variables. Secret values come from the
  environment at apply time, but they still end up in state.

#### `envs/<env>/`

One directory per environment, each containing one root module per stack. Environments should look alike: same stacks,
same modules, different inputs. Differences (server size, domain, replicas) belong in variables, not forked code.

- `envs/prod/cluster`: Hetzner SSH key, firewall, server with cloud-init that installs k3s, and outputs (IPv4/IPv6)
  for later stacks. Flux is bootstrapped against the cluster afterwards; workloads live in GitOps manifests, not here.
- `envs/prod/webapp`: infrastructure the web application needs outside the cluster, such as DNS records pointing at it,
  and any storage or external services. Depends on `cluster` for the server address. The app itself is deployed by Flux.

### Apply order

1. `bootstrap`
1. `shared/*`
1. `envs/<env>/cluster`
1. other stacks in the environment (for example `webapp`)

Tear down in reverse order.

### Conventions

- One state per root module, so a change in one stack cannot damage another.
- Root modules contain wiring only: providers, backend, variables, and calls to `modules/`.
- Pass values between stacks explicitly (variables, data sources, or `terraform_remote_state`), never by sharing state files.
- Secrets never enter git. Tokens come from environment variables, and local values from a gitignored `terraform.tfvars`.
  Commit a `terraform.tfvars.example` instead.
- Commit `.terraform.lock.hcl`. Never commit state.

## Consequences

Positive:

- Small, independent states: a bad apply or a corrupted state affects one stack.
- Adding an environment is a copy of an existing `envs/<env>` directory with different inputs.
- `bootstrap` isolates the only stack that needs local state.
- Account-wide things (DNS zone, GitHub settings) are not duplicated per environment.

Negative:

- More directories, and more `init`/`apply` runs than a single root module. Apply order matters.
- Cross-stack values must be passed explicitly.
- Some provider and backend boilerplate is repeated in each root module.

## Alternatives considered

- **Single root module with workspaces.** Simplest, but all resources share one state and workspaces make it easy
  to apply to the wrong environment.
- **One directory per environment, each a single root module.** Fewer directories, but a cluster change and a DNS change
  share a state and a blast radius.
- **Terragrunt.** Removes the boilerplate but adds a tool to learn and maintain. Can be revisited if the boilerplate becomes a burden.

## Possible future changes

- **Staging environment.** Add `envs/staging/` mirroring `envs/prod` with smaller inputs (one small VPS), destroyed
  when not in use. Needs its own subdomain records and state keys. Deliberately not created yet.
- **Test or ephemeral environments.** Short-lived copies of an environment, for example per pull request, created and
  destroyed by CI. Would need unique names and state keys per instance.
- **Remote state for `bootstrap`.** Migrate its state into the bucket it created.
- **Key management for state encryption.** Currently one passphrase (via `TF_ENCRYPTION`) shared by all stacks; could move to per-stack keys or an external key provider.
- **More stacks per environment**, such as monitoring or backups, if they warrant separate state.
- **Terragrunt or a generator** if the repeated boilerplate becomes a burden.
- **Extracting modules** from `cluster` as soon as a second environment needs the same code.
