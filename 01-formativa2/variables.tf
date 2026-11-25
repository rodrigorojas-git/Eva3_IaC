variable "region" {
  type = string
}

variable "proyecto" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "cidr_subredes" {
  type = list(string)
}

variable "buckets" {
  type = set(string)
}

variable "ami_id" {
  type = string
}
