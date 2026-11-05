# Credentials come from the environment, never from files in git:
#   export CLOUDFLARE_API_TOKEN=...   # needs Account > Workers R2 Storage: Edit
provider "cloudflare" {}
