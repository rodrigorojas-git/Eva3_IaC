variable "nombre" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subredes" {
  type = list(string)
}

variable "instancias" {
  type = map(string)
}

variable "tags" {
  type = map(string)
}
