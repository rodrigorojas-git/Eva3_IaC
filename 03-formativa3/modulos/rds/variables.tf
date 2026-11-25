variable "nombre" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subredes" {
  type = list(string)
}

variable "sg_servidores" {
  type = string
}

variable "clase" {
  type = string
}

variable "usuario" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}

variable "ambiente" {
  type = string
}

variable "tags" {
  type = map(string)
}
