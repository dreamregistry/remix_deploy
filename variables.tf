variable "dream_env" {
  description = "dream app environment variables to set"
  type        = any
  default     = {}
}

variable "dream_secrets" {
  description = "dream app secrets to set"
  type        = set(string)
  default     = []
}

variable "dream_project_dir" {
  description = "root directory of the project sources"
  type        = string
}

variable "root_url" {
  type        = string
  description = "Application root url"
}
