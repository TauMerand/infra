variable "account_id" {
  description = "Cloudflare account ID that owns the R2 bucket."
  type        = string
}

variable "bucket_name" {
  description = "Name of the R2 bucket that holds OpenTofu state for all other stacks."
  type        = string
  default     = "tfstate"
}

variable "location" {
  description = "R2 location hint: apac, eeur, enam, weur, wnam or oc. Only a hint; Cloudflare may place the data elsewhere."
  type        = string
  default     = "weur"

  validation {
    condition     = contains(["apac", "eeur", "enam", "weur", "wnam", "oc"], var.location)
    error_message = "location must be one of apac, eeur, enam, weur, wnam, oc."
  }
}
