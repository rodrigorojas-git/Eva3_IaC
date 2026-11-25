region      = "us-east-1"
proyecto    = "eduandes"
aplicacion  = "biblioteca"
ambiente    = "dev" # cambiar a "prod" para probar los condicionales
responsable = "rodrigo"

vpc_cidr = "10.0.0.0/16"

subredes = {
  publica-1 = { cidr = "10.0.1.0/24", az = "us-east-1a", publica = true }
  publica-2 = { cidr = "10.0.2.0/24", az = "us-east-1b", publica = true }
  privada-1 = { cidr = "10.0.11.0/24", az = "us-east-1a", publica = false }
  privada-2 = { cidr = "10.0.12.0/24", az = "us-east-1b", publica = false }
}

servidores = {
  biblioteca-a = { tipo = "t3.medium", disco = 30, subred = "publica-1" }
  biblioteca-b = { tipo = "t3.medium", disco = 30, subred = "publica-1" }
  biblioteca-c = { tipo = "t3.large", disco = 60, subred = "publica-2" }
}

ami_id = "ami-0c230065b91270bc6" # Amazon Linux 2023 (us-east-1)
llave  = "vockey"

db_clase    = "db.t3.micro"
db_usuario  = "admin"
db_password = "Biblioteca2026" # va en tfvars, nunca en un .tf
