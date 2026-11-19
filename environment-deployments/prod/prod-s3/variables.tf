variable "bucket_name" {
  type = string
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "region" {
  type = string
}

variable "enable_versioning" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
