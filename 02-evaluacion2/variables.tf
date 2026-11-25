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

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "cantidad_ec2" {
  type = number
}

variable "cantidad_nlb" {
  type = number
}

variable "buckets" {
  type = set(string)
}

variable "db_engine_version" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "db_usuario" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "prefijo" {
  type = string
}

variable "nombre" {
  type = string
}