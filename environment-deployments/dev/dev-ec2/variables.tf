variable "name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
