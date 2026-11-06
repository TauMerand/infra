# Credentials come from the environment, never from files in git:
#   export GITHUB_TOKEN=...   # fine-grained PAT, see docs/bootstrap.md
provider "github" {
  owner = var.owner
}
