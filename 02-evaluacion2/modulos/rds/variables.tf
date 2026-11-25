variable "prefijo" {
  type = string
}

variable "nombre" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "engine_version" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "usuario" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}
