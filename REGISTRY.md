# Terraform Registry: links + código estándar

Cada recurso con su link a la documentación oficial y el código mínimo para usarlo.

| Recurso | Sección |
|---|---|
| Providers, random, locals | [Providers](#providers) · [Random](#random--locals) |
| Red | [VPC](#vpc--zonas) · [Subnet](#subnet) · [IGW + rutas](#internet-gateway--route-table--asociación) · [Subredes con map](#subredes-públicas-y-privadas-con-un-solo-bloque-map--for_each) |
| Cómputo | [Security Group](#security-group) · [EC2](#ec2-ami-por-variable) · [EC2 disco + user_data](#ec2-con-disco-y-user_data) |
| Balanceo | [NLB](#network-load-balancer) · [Target group + listener](#target-group--listener--attachment) |
| Base de datos | [RDS](#rds-subnet-group--security-group--instancia) |
| Almacenamiento | [S3 privado](#s3-privado-si-el-lab-lo-permite) · [S3 local-exec](#s3-con-local-exec-learner-lab) · [S3 versionado](#s3-con-versionado) |
| Otros | [ID de cuenta](#id-de-la-cuenta-para-nombres-únicos) · [Docs del lenguaje](#documentación-del-lenguaje) |

---

### Providers
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs
```hcl
terraform {
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.1" }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

### Random + locals
🔗 https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string
```hcl
resource "random_string" "sufijo" {
  length  = 6
  upper   = false
  special = false
}

locals {
  prefijo = "${var.proyecto}-${random_string.sufijo.result}"
}
```

### VPC + zonas
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones
```hcl
resource "aws_vpc" "vpc_principal" {
  cidr_block = "10.0.0.0/16"
}

data "aws_availability_zones" "disponibles" {
  state = "available"
}
```

### Subnet
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
```hcl
resource "aws_subnet" "subred_publica" {
  count                   = 2
  vpc_id                  = aws_vpc.vpc_principal.id
  cidr_block              = ["10.0.1.0/24", "10.0.2.0/24"][count.index]
  availability_zone       = data.aws_availability_zones.disponibles.names[count.index]
  map_public_ip_on_launch = true
}
```

### Internet Gateway + route table + asociación
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
```hcl
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_principal.id
}

resource "aws_route_table" "tabla_publica" {
  vpc_id = aws_vpc.vpc_principal.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "asociacion_publica" {
  count          = 2
  subnet_id      = aws_subnet.subred_publica[count.index].id
  route_table_id = aws_route_table.tabla_publica.id
}
```

### Security Group
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
```hcl
resource "aws_security_group" "sg_web" {
  name   = "sg-web"
  vpc_id = aws_vpc.vpc_principal.id

  dynamic "ingress" {
    for_each = [22, 80]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### EC2 (AMI por variable)
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
```hcl
variable "ami_id" {
  type = string
}
# terraform.tfvars → ami_id = "ami-0..."

resource "aws_instance" "servidor" {
  count                  = 2
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subred_publica[count.index].id
  key_name               = "vockey"
  vpc_security_group_ids = [aws_security_group.sg_web.id]
}
```

**Alternativa: buscar la AMI automáticamente** (sin pegar el ID)
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
```hcl
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}
# en la instancia: ami = data.aws_ami.al2023.id
```

### Network Load Balancer
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
```hcl
resource "aws_lb" "nlb" {
  name               = "mi-nlb"          # máx. 32 caracteres
  load_balancer_type = "network"
  subnets            = [aws_subnet.subred_publica[0].id]
}
```

<a id="alb"></a>**ALB:** `load_balancer_type = "application"`, `subnets = aws_subnet.subred_publica[*].id` (mínimo 2, en AZ distintas) y `security_groups = [aws_security_group.sg_web.id]`.

### Target group + listener + attachment
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment
```hcl
resource "aws_lb_target_group" "tg_web" {
  name     = "tg-web"
  port     = 80
  protocol = "TCP"                       # ALB: "HTTP"
  vpc_id   = aws_vpc.vpc_principal.id
}

resource "aws_lb_listener" "escucha_web" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"              # ALB: "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_web.arn
  }
}

resource "aws_lb_target_group_attachment" "registro_web" {
  count            = 2
  target_group_arn = aws_lb_target_group.tg_web.arn
  target_id        = aws_instance.servidor[count.index].id
  port             = 80
}
```

### S3 privado (si el lab lo permite)
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
```hcl
resource "aws_s3_bucket" "bucket_privado" {
  for_each = toset(["datos", "logs"])
  bucket   = "${local.prefijo}-${each.key}"
}

resource "aws_s3_bucket_public_access_block" "bloqueo" {
  for_each                = aws_s3_bucket.bucket_privado
  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### S3 con local-exec (Learner Lab)
```hcl
resource "null_resource" "bucket_privado" {
  for_each = toset(["datos", "logs"])
  triggers = { bucket = "${local.prefijo}-${each.key}" }

  provisioner "local-exec" {
    command = "aws s3api create-bucket --bucket ${self.triggers.bucket} --region us-east-1"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "aws s3 rb s3://${self.triggers.bucket} --force"
  }
}
```

### RDS (subnet group + security group + instancia)
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group
```hcl
resource "aws_db_subnet_group" "rds" {
  name       = "mi-rds-subnets"
  subnet_ids = [aws_subnet.privada_1.id, aws_subnet.privada_2.id] # mínimo 2 AZ distintas
}

resource "aws_security_group" "sg_rds" {
  name   = "sg-rds"
  vpc_id = aws_vpc.vpc_principal.id

  ingress {
    from_port       = 3306                              # PostgreSQL: 5432
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web.id]    # solo desde los servidores
  }
}

resource "aws_db_instance" "db" {
  identifier             = "mi-db"
  engine                 = "mysql"                      # o "postgres"
  engine_version         = "8.0"                        # opcional (PostgreSQL: "18.3")
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = var.db_usuario
  password               = var.db_password              # variable sensitive
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.sg_rds.id]
  publicly_accessible    = false
  multi_az               = false
  skip_final_snapshot    = true                         # sin esto el destroy falla
}
```

### S3 con versionado
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning
```hcl
resource "aws_s3_bucket" "bucket" {
  bucket        = "mi-bucket-unico-123"
  force_destroy = true # permite destroy con archivos dentro
}

resource "aws_s3_bucket_versioning" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = "Enabled" # o "Suspended"
  }
}
```

### Subredes públicas y privadas con un solo bloque (map + for_each)
```hcl
variable "subredes" {
  type = map(object({
    cidr    = string
    az      = string
    publica = bool
  }))
}

resource "aws_subnet" "subred" {
  for_each                = var.subredes
  vpc_id                  = aws_vpc.vpc_principal.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.publica
}

# solo las públicas a la tabla con IGW
resource "aws_route_table_association" "publica" {
  for_each       = { for k, s in var.subredes : k => s if s.publica }
  subnet_id      = aws_subnet.subred[each.key].id
  route_table_id = aws_route_table.tabla_publica.id
}
```

### EC2 con disco y user_data
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#root_block_device
```hcl
resource "aws_instance" "servidor" {
  # ... ami, instance_type, subnet_id ...

  root_block_device {
    volume_size = 30 # GB
  }

  user_data = <<-EOT
    #!/bin/bash
    dnf install -y httpd mariadb105
    systemctl enable --now httpd
  EOT
}
```

### ID de la cuenta (para nombres únicos)
🔗 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity
```hcl
data "aws_caller_identity" "cuenta" {}
# uso: data.aws_caller_identity.cuenta.account_id
```

### Documentación del lenguaje
- Funciones: https://developer.hashicorp.com/terraform/language/functions
- Condicionales: https://developer.hashicorp.com/terraform/language/expressions/conditionals
- Expresiones for: https://developer.hashicorp.com/terraform/language/expressions/for
- Bloques dynamic: https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks
- Variables: https://developer.hashicorp.com/terraform/language/values/variables
- Módulos: https://developer.hashicorp.com/terraform/language/modules/syntax
- Provisioners: https://developer.hashicorp.com/terraform/language/provisioners
- Debugging: https://developer.hashicorp.com/terraform/internals/debugging
