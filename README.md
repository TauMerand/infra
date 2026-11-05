# infra

Infrastructure as code and GitOps for a single-node [k3s](https://k3s.io) cluster on a Hetzner VPS, with DNS on Cloudflare.

## Stack

| Layer | Tool |
| --- | --- |
| Provisioning | [OpenTofu](https://opentofu.org) |
| Compute / network | Hetzner Cloud (`hcloud` provider) |
| DNS | Cloudflare (`cloudflare` provider) |
| Kubernetes | k3s |
| GitOps | [Flux](https://fluxcd.io) |
| Checks | pre-commit, gitleaks, `tofu fmt`, tflint |

## Layout

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
docs/                 # detailed documentation (see docs/bootstrap.md)
```

Each applied directory is a separate root module with its own state. The reasoning, apply order, conventions and
planned changes (such as a staging environment) are in
[docs/adr/0001-terraform-directory-structure.md](docs/adr/0001-terraform-directory-structure.md).

Flux manifests (cluster config, infrastructure, apps) will be added once the cluster exists.

## Secrets

Nothing secret is committed.

- API tokens come from environment variables (`HCLOUD_TOKEN`, `CLOUDFLARE_API_TOKEN`).
- Per-environment values go in a gitignored `terraform.tfvars` (copy from `terraform.tfvars.example`).
- State can contain secrets. `terraform/bootstrap` uses local (gitignored) state; every other stack will use the Cloudflare R2 bucket it creates.
- `.gitignore` covers keys, certs, kubeconfigs and env files, and gitleaks runs as a pre-commit hook.

## Usage

```sh
pre-commit install            # once per clone

# apply order: bootstrap -> shared/* -> envs/<env>/<stack>
cd terraform/bootstrap
tofu init && tofu apply
```

Repeat `tofu init && tofu apply` in each stack in order. See [docs/bootstrap.md](docs/bootstrap.md) for the full procedure.

## Roadmap

- [ ] Hetzner: server, firewall, cloud-init with k3s
- [ ] Cloudflare: DNS records managed in code (import existing records)
- [ ] Remote state on Cloudflare R2
- [ ] Bootstrap Flux against this repo
- [ ] Ingress controller and cert-manager (Let's Encrypt via Cloudflare DNS-01)
- [ ] Sample app end to end (DNS, TLS, pod)
- [ ] Backups (k3s snapshots, Hetzner backups)
- [ ] Monitoring
- [ ] CI: `tofu plan` on pull requests
- [ ] Restrict admin access (SSH and the Kubernetes API) behind a VPN
