variable "nombre" {
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

variable "tags" {
  type = map(string)
}
