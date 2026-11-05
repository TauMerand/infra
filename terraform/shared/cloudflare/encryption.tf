# OpenTofu native state and plan encryption.
#
# The key provider (which holds the passphrase) is deliberately NOT here: it is
# supplied through the TF_ENCRYPTION environment variable so the secret never
# enters git. OpenTofu merges that with this block. Set it before running tofu:
#
#   export TF_ENCRYPTION='key_provider "pbkdf2" "main" { passphrase = "<16+ chars>" }'
#
# See docs/bootstrap.md. Losing the passphrase means losing access to the state.
terraform {
  encryption {
    method "aes_gcm" "main" {
      keys = key_provider.pbkdf2.main
    }

    state {
      method   = method.aes_gcm.main
      enforced = true # refuse to read or write unencrypted state
    }

    plan {
      method   = method.aes_gcm.main
      enforced = true
    }
  }
}
