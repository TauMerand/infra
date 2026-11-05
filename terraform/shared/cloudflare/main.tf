# DNS records for the domain that are not tied to one environment.
# Existing records were brought under management with import blocks (see imports.tf).
#
# Email posture: this domain sends no mail, so SPF rejects everything, DKIM publishes an
# empty key, and DMARC rejects with strict alignment. Reports go to Cloudflare DMARC Management.

resource "cloudflare_dns_record" "spf" {
  zone_id = var.zone_id
  name    = var.domain
  type    = "TXT"
  content = "\"v=spf1 -all\""
  ttl     = 1 # automatic
  proxied = false
}

resource "cloudflare_dns_record" "dkim_wildcard" {
  zone_id = var.zone_id
  name    = "*._domainkey.${var.domain}"
  type    = "TXT"
  content = "\"v=DKIM1; p=\""
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "dmarc" {
  zone_id = var.zone_id
  name    = "_dmarc.${var.domain}"
  type    = "TXT"
  content = "\"v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s; rua=mailto:bdcec9d10958489bb3aa49d7c89d9a24@dmarc-reports.cloudflare.net;\""
  ttl     = 1
  proxied = false
}
