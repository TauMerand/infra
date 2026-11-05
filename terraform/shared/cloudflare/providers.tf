# Credentials come from the environment, never from files in git:
#   export CLOUDFLARE_API_TOKEN=...   # Zone > DNS > Edit on this zone only (plus Zone > Zone > Read to look up the ID)
provider "cloudflare" {}
