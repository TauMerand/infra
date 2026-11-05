resource "cloudflare_r2_bucket" "tfstate" {
  account_id = var.account_id
  name       = var.bucket_name
  location   = var.location

  # State is precious. Make accidental destruction require an explicit edit.
  lifecycle {
    prevent_destroy = true
  }
}
