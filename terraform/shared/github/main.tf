# Repositories managed from code. Add a module block per repo.
module "infra" {
  source = "../../modules/github-repo"

  name        = "infra"
  description = "OpenTofu/Terraform IAC and GitOps for managing infrastructure across projects - primarily Hetzner for personal projects"
  visibility  = "public"
  topics      = ["opentofu", "k3s", "hetzner", "cloudflare", "gitops", "flux"]
}

# Add blocks for future repos that
