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
tf/hetzner      server, firewall, SSH key, cloud-init
tf/cloudflare   DNS records
docs/           detailed documentation (see docs/bootstrap.md)
```

Flux manifests (cluster config, infrastructure, apps) will be added once the cluster exists.

## Secrets

Nothing secret is committed.

- API tokens come from environment variables (`HCLOUD_TOKEN`, `CLOUDFLARE_API_TOKEN`).
- Per-environment values go in a gitignored `terraform.tfvars` (copy from `terraform.tfvars.example`).
- State is local and gitignored for now, and can contain secrets. It will move to a Cloudflare R2 backend.
- `.gitignore` covers keys, certs, kubeconfigs and env files, and gitleaks runs as a pre-commit hook.

## Usage

```sh
pre-commit install            # once per clone

cd tf/hetzner
tofu init && tofu apply

cd ../cloudflare
tofu init && tofu apply
```

See [docs/bootstrap.md](docs/bootstrap.md) for the full bootstrap procedure.

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
