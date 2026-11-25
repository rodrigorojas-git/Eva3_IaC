variable "nombre" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subred_ids" {
  type = map(string)
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

variable "ambiente" {
  type = string
}

variable "tags" {
  type = map(string)
}
