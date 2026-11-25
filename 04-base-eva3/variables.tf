variable "region" {
  type = string
}

variable "proyecto" {
  type = string
}

variable "aplicacion" {
  type = string
}

variable "ambiente" {
  type = string

  validation {
    condition     = contains(["dev", "prod"], var.ambiente)
    error_message = "ambiente debe ser \"dev\" o \"prod\"."
  }
}

variable "responsable" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "subredes" {
  type = map(object({
    cidr    = string
    az      = string
    publica = bool
  }))
}

variable "servidores" {
  type = map(object({
    tipo   = string
    disco  = number
    subred = string
  }))
}

variable "ami_id" {
  type = string
}

variable "llave" {
  type = string
}

variable "db_clase" {
  type = map(string)
}

variable "db_usuario" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}
