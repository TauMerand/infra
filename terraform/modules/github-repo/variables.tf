variable "name" {
  description = "Repository name."
  type        = string
}

variable "description" {
  description = "Short repository description."
  type        = string
  default     = ""
}

variable "visibility" {
  description = "public or private."
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.visibility)
    error_message = "visibility must be public or private."
  }
}

variable "topics" {
  description = "Repository topics."
  type        = list(string)
  default     = []
}

variable "default_branch" {
  description = "Default branch that the ruleset protects."
  type        = string
  default     = "main"
}

variable "required_approving_review_count" {
  description = "Approvals needed to merge a PR. 0 suits a solo maintainer; a PR is still required."
  type        = number
  default     = 0
}

variable "required_status_checks" {
  description = "Status check contexts that must pass before merging (for example [\"lint\"]). Empty until CI exists."
  type        = list(string)
  default     = []
}
