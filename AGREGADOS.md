# Agregados que puede pedir el profe

El profe toma **el ejercicio formativo anterior y le agrega cosas**. Este archivo tiene el código listo para cada agregado probable, indicando qué archivo tocar. Todo está validado sobre las carpetas del repo.

- [Parte 1: agregados probables sobre la Formativa 3](#parte-1-agregados-probables-sobre-la-formativa-3) ← **próxima prueba**
- [Parte 2: agregados sobre la Formativa 2](#parte-2-agregados-sobre-la-formativa-2) (prueba anterior)

Después de cualquier cambio: `terraform init` (si agregaste un módulo o provider) → `terraform validate` → `plan` → `apply`.

---

## Parte 1: agregados probables sobre la Formativa 3

Base: [`03-formativa3/`](03-formativa3/). Basado en lo que cambió de la Formativa 2 a la Evaluación 2.

| # | Agregado | Probabilidad | Qué tocar |
|---|---|---|---|
| A1 | [Cambiar cantidades / 4º servidor / otros CIDR](#a1-cambiar-cantidades--4º-servidor--otros-cidr) | Muy alta | Solo `.tfvars` |
| A2 | [`dev.tfvars` y `prod.tfvars`](#a2-devtfvars-y-prodtfvars) | Muy alta | Archivos nuevos |
| A3 | [random de N caracteres + 2 locals por módulo](#a3-random--2-locals-en-todos-los-módulos) | Alta | Todos los `main.tf` |
| A4 | [Más funciones: `lookup`, `length`, `keys`](#a4-más-funciones-lookup-length-keys) | Alta | Raíz |
| A5 | [Validación de `ambiente`](#a5-validación-de-ambiente) | Alta | `variables.tf` raíz |
| A6 | [Más condicionales prod/dev](#a6-más-condicionales-proddev) | Alta | Módulos |
| A7 | [Crear un recurso solo si se pide (`count ? 1 : 0`)](#a7-crear-un-recurso-solo-si-se-pide) | Media | Raíz |
| A8 | [Puertos con `dynamic`](#a8-puertos-con-dynamic) | Media | Módulo ec2 |
| A9 | [Varios buckets con `for_each`](#a9-varios-buckets-con-for_each) | Media | Módulo s3 |
| A10 | [Debugging en `su-nombre.log` + entregables](#a10-debugging-en-su-nombrelog--entregables) | Muy alta | Comandos |
| — | [Plan B: S3 con `local-exec`](#plan-b-s3-con-local-exec) | Si falla S3 | Módulo s3 |

---

### A1. Cambiar cantidades / 4º servidor / otros CIDR

Solo **`terraform.tfvars`**. No se toca código.

```hcl
servidores = {
  biblioteca-a = { tipo = "t3.medium", disco = 30, subred = "publica-1" }
  biblioteca-b = { tipo = "t3.medium", disco = 30, subred = "publica-1" }
  biblioteca-c = { tipo = "t3.large", disco = 60, subred = "publica-2" }
  biblioteca-d = { tipo = "t3.medium", disco = 30, subred = "publica-2" } # nuevo
}
```
- Mover un servidor de subred: cambiar su `subred` (debe ser una clave pública del mapa `subredes`).
- Otros CIDR o más subredes: editar el mapa `subredes`. Las privadas deben quedar en **2 AZ distintas** (la RDS lo exige).
- Ojo con nombres largos: `proyecto` + `aplicacion` + `ambiente` + `-nlb` debe tener **máximo 32 caracteres**.

---

### A2. dev.tfvars y prod.tfvars

En la Evaluación 2 pidió `dev.tfvars`. Renombra `terraform.tfvars` → **`dev.tfvars`** y crea una copia **`prod.tfvars`** cambiando solo:
```hcl
ambiente = "prod"
```
Comandos:
```powershell
terraform plan  -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
terraform plan  -var-file="prod.tfvars"   # sin apply
```
`terraform.tfvars` se carga solo; cualquier otro nombre necesita `-var-file`.

---

### A3. random + 2 locals en todos los módulos

**`providers.tf`**: agregar el provider random dentro de `required_providers`:
```hcl
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
```

**`main.tf` raíz**: agregar el recurso y el comentario arriba del `locals`, y usar el random en el bucket:
```hcl
resource "random_string" "sufijo" {
  length  = 10
  upper   = false
  special = false
}

# LOCALS por módulo:
# - raíz: nombre, bucket, tags  (este archivo)
# - vpc : nombre_vpc, publicas  (modulos/vpc/main.tf)
# - ec2 : nombre_sg, factor     (modulos/ec2/main.tf)
# - nlb : nombre_nlb, nombre_tg (modulos/nlb/main.tf)
# - rds : nombre_db, motor      (modulos/rds/main.tf)
# - s3  : nombre_bucket, estado (modulos/s3/main.tf)
```
```hcl
  bucket = format("%s-%s", local.nombre, random_string.sufijo.result)
```
(Si ya no usas el ID de cuenta, puedes borrar `data "aws_caller_identity"`.)

**Un `locals` al inicio de cada `modulos/*/main.tf`, y reemplazar donde se usa:**

`modulos/vpc/main.tf`
```hcl
locals {
  nombre_vpc = "${var.nombre}-vpc"
  publicas   = { for k, s in var.subredes : k => s if s.publica }
}
# aws_vpc:                    tags     = merge(var.tags, { Name = local.nombre_vpc })
# aws_route_table_association: for_each = local.publicas
```

`modulos/ec2/main.tf`
```hcl
locals {
  nombre_sg = "${var.nombre}-sg-servidores"
  factor    = var.ambiente == "prod" ? 2 : 1 # condicional
}
# aws_security_group: name        = local.nombre_sg
# root_block_device:  volume_size = each.value.disco * local.factor
```

`modulos/nlb/main.tf`
```hcl
locals {
  nombre_nlb = "${var.nombre}-nlb"
  nombre_tg  = "${var.nombre}-tg"
}
# aws_lb:              name = local.nombre_nlb
# aws_lb_target_group: name = local.nombre_tg
```

`modulos/rds/main.tf`
```hcl
locals {
  nombre_db = "${var.nombre}-mysql"
  motor     = "mysql"
}
# aws_db_instance: identifier = local.nombre_db
#                  engine     = local.motor
```

`modulos/s3/main.tf`
```hcl
locals {
  nombre_bucket = var.bucket
  estado        = var.ambiente == "prod" ? "Enabled" : "Suspended" # condicional
}
# aws_s3_bucket:              bucket = local.nombre_bucket
# versioning_configuration:   status = local.estado
```

---

### A4. Más funciones: lookup, length, keys

**Tamaño de la RDS según el ambiente con `lookup`.**

`variables.tf` raíz: cambiar el tipo de `db_clase`:
```hcl
variable "db_clase" {
  type = map(string)
}
```
`terraform.tfvars`:
```hcl
db_clase    = { dev = "db.t3.micro", prod = "db.t3.small" }
```
`main.tf` raíz, dentro de `module "rds"`:
```hcl
  clase         = lookup(var.db_clase, var.ambiente, "db.t3.micro")
```
`lookup(mapa, clave, default)`: busca `ambiente` en el mapa; si no existe, usa el default.

**Outputs con `length` y `keys`** (`outputs.tf` raíz):
```hcl
output "cantidad_servidores" {
  value = length(var.servidores)
}

output "nombres_servidores" {
  value = keys(var.servidores)
}
```

---

### A5. Validación de ambiente

`variables.tf` raíz, reemplazar la variable `ambiente`:
```hcl
variable "ambiente" {
  type = string

  validation {
    condition     = contains(["dev", "prod"], var.ambiente)
    error_message = "ambiente debe ser \"dev\" o \"prod\"."
  }
}
```
Probar: `terraform plan -var="ambiente=qa"` → muestra tu mensaje de error.

---

### A6. Más condicionales prod/dev

Todos usan `ambiente`, que cada módulo ya recibe.

**RDS: backups solo en prod** (`modulos/rds/main.tf`, dentro de `aws_db_instance`):
```hcl
  backup_retention_period = var.ambiente == "prod" ? 7 : 0
```

**EC2: tipo de instancia según el ambiente** (si lo piden en vez del tipo del mapa), en `aws_instance`:
```hcl
  instance_type = var.ambiente == "prod" ? each.value.tipo : "t3.micro"
```

**RDS: más almacenamiento en prod:**
```hcl
  allocated_storage = var.ambiente == "prod" ? 50 : 20
```

> Evita `deletion_protection = true` en prod: si lo aplicas, el `destroy` falla.

---

### A7. Crear un recurso solo si se pide

Ejemplo con la RDS (sirve igual para cualquier módulo).

`variables.tf` raíz:
```hcl
variable "crear_rds" {
  type = bool
}
```
`terraform.tfvars`:
```hcl
crear_rds = true
```
`main.tf` raíz, en `module "rds"` debajo de `source`:
```hcl
  count  = var.crear_rds ? 1 : 0
```
`outputs.tf` raíz, el output de la RDS queda:
```hcl
output "rds_endpoint" {
  value = var.crear_rds ? module.rds[0].endpoint : "RDS no creada"
}
```
Con `count`, el módulo se referencia con índice: `module.rds[0]`.

---

### A8. Puertos con dynamic

`modulos/ec2/variables.tf`, agregar:
```hcl
variable "puertos" {
  type = list(number)
}
```
`modulos/ec2/main.tf`: en el security group, reemplazar los dos bloques `ingress` (22 y 80) por:
```hcl
  dynamic "ingress" {
    for_each = var.puertos
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
```
`variables.tf` raíz:
```hcl
variable "puertos" {
  type = list(number)
}
```
`terraform.tfvars`:
```hcl
puertos = [22, 80]
```
`main.tf` raíz, dentro de `module "ec2"`:
```hcl
  puertos    = var.puertos
```
El 22 (SSH) y el 80 (web/NLB) tienen que estar siempre.

---

### A9. Varios buckets con for_each

`variables.tf` raíz:
```hcl
variable "buckets" {
  type = set(string)
}
```
`terraform.tfvars`:
```hcl
buckets = ["material", "reportes", "respaldos"]
```
`main.tf` raíz, dentro de `module "s3"`:
```hcl
  buckets  = var.buckets
```
`modulos/s3/variables.tf`, agregar:
```hcl
variable "buckets" {
  type = set(string)
}
```
`modulos/s3/main.tf` (reemplazar todo):
```hcl
resource "aws_s3_bucket" "bucket" {
  for_each = var.buckets

  bucket        = format("%s-%s", var.bucket, each.key)
  force_destroy = true
  tags          = merge(var.tags, { Name = format("%s-%s", var.bucket, each.key) })
}

resource "aws_s3_bucket_versioning" "bucket" {
  for_each = aws_s3_bucket.bucket

  bucket = each.value.id

  versioning_configuration {
    status = var.ambiente == "prod" ? "Enabled" : "Suspended" # condicional
  }
}
```
`modulos/s3/outputs.tf` (reemplazar):
```hcl
output "bucket" {
  value = [for b in aws_s3_bucket.bucket : b.bucket]
}
```

---

### A10. Debugging en su-nombre.log + entregables

```powershell
$env:TF_LOG="DEBUG"
$env:TF_LOG_PATH="rodrigo.log"
terraform plan
terraform apply
Remove-Item Env:TF_LOG, Env:TF_LOG_PATH
```
Entregables típicos (Evaluación 2): **ZIP** con todos los `.tf`, el `.tfvars`, el `.log`, y un **Word** con pantallazos del paso a paso (`init`, `validate`, debugging, `plan`, `apply`, `output`, consola de AWS, `destroy`). No incluir `.terraform/`, `terraform.tfstate` ni `labsuser.pem`.

---

### Plan B: S3 con local-exec

Si `aws_s3_bucket` falla en el Learner Lab, reemplaza el módulo S3 de la Formativa 3:

`modulos/s3/main.tf` (reemplazar todo):
```hcl
resource "null_resource" "bucket" {
  triggers = {
    bucket = var.bucket
    region = var.region
    estado = var.ambiente == "prod" ? "Enabled" : "Suspended" # condicional
  }

  provisioner "local-exec" {
    command = "aws s3api create-bucket --bucket ${self.triggers.bucket} --region ${self.triggers.region} && aws s3api put-bucket-versioning --bucket ${self.triggers.bucket} --versioning-configuration Status=${self.triggers.estado}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws s3 rb s3://${self.triggers.bucket} --force"
  }
}
```
`modulos/s3/variables.tf` (reemplazar todo):
```hcl
variable "bucket" {
  type = string
}

variable "ambiente" {
  type = string
}

variable "region" {
  type = string
}
```
`modulos/s3/outputs.tf` (reemplazar):
```hcl
output "bucket" {
  value = null_resource.bucket.triggers.bucket
}
```
`main.tf` raíz, `module "s3"` queda:
```hcl
module "s3" {
  source = "./modulos/s3"

  bucket   = local.bucket
  region   = var.region
  ambiente = var.ambiente
}
```
Luego `terraform init` (descarga el provider `null`). Solo se hace `apply` en dev: con versionado activo (prod), `aws s3 rb --force` no borra las versiones.

---

## Parte 2: agregados sobre la Formativa 2

Base: [`01-formativa2/`](01-formativa2/). Agregados de la prueba anterior (remote-exec, local-exec, dynamic, NLB → EC2, etc.).

| # | Agregado | Probabilidad |
|---|---|---|
| B1 | [Apache con `remote-exec` + puerto 80](#b1-apache-con-remote-exec--puerto-80) | Alta |
| B2 | [Guardar IPs en un archivo con `local-exec`](#b2-guardar-ips-en-un-archivo-con-local-exec) | Alta |
| B3 | [Puertos con `dynamic`](#b3-puertos-con-dynamic) | Alta |
| B4 | [Conectar NLB con las EC2](#b4-conectar-nlb-con-las-ec2) | Media |
| B5 | [`for_each` en vez de `count` (EC2)](#b5-for_each-en-vez-de-count-ec2) | Media |
| B6 | [Validaciones y más outputs](#b6-validaciones-y-más-outputs) | Media |
| B7 | [Módulo `sg` separado](#b7-módulo-sg-separado) | Baja |
| B8 | [Route table "principal"](#b8-route-table-principal) | Baja |
| B9 | [Cambiar cantidades](#b9-cambiar-cantidades) | Baja |

---

### B1. Apache con remote-exec + puerto 80

**`modulos/ec2/main.tf`**: en el security group, agrega este bloque junto al `ingress` del 22. Si usas el agregado B3, no lo agregues: basta con poner `80` en la lista de puertos.
```hcl
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
```
Reemplaza el `provisioner "remote-exec"` de la instancia por:
```hcl
  provisioner "remote-exec" {
    inline = [
      "sudo dnf install -y httpd",
      "sudo systemctl enable --now httpd",
      "echo '<h1>${local.nombre}</h1>' | sudo tee /var/www/html/index.html",
    ]
  }
```

**`outputs.tf` (raíz)**, opcional, para tener el link directo:
```hcl
output "urls_web" {
  value = [for ip in module.ec2[*].public_ip : "http://${ip}"]
}
```

**Probar:** abre la URL en el navegador (con `http://`, no `https://`) y saca un pantallazo con el nombre de la instancia.

---

### B2. Guardar IPs en un archivo con local-exec

**`modulos/ec2/main.tf`**: dentro de `resource "aws_instance" "servidor"`, debajo del `remote-exec`:
```hcl
  provisioner "local-exec" {
    command = "echo ${local.nombre} ${self.public_ip} >> ips.txt"
  }
```

**Probar:** después del `apply` aparece `ips.txt` en `01-formativa2/`, con una línea por instancia. Bórralo antes de repetir el `apply`, porque `>>` agrega líneas al final.

---

### B3. Puertos con dynamic

Reemplaza el `ingress` fijo por una lista de puertos que viene del tfvars.

**`modulos/ec2/variables.tf`**, agregar:
```hcl
variable "puertos" {
  type = list(number)
}
```

**`modulos/ec2/main.tf`**: en el security group, reemplaza el bloque `ingress { ... 22 ... }` por:
```hcl
  dynamic "ingress" {
    for_each = var.puertos
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
```

**`variables.tf` (raíz)**, agregar:
```hcl
variable "puertos" {
  type = list(number)
}
```

**`main.tf` (raíz)**: dentro de `module "ec2"`, agrega:
```hcl
  puertos   = var.puertos
```

**`terraform.tfvars`**, agregar:
```hcl
puertos       = [22, 80]
```

`ingress.value` es cada puerto de la lista. **El 22 siempre tiene que estar**, porque lo necesita el `remote-exec`.

---

### B4. Conectar NLB con las EC2

Cada NLB reenvía el puerto 80 a la EC2 de su misma subred. **Requiere el agregado B1** (Apache + puerto 80); sin un servidor web, el target queda *unhealthy*.

**`modulos/nlb/variables.tf`**, agregar:
```hcl
variable "vpc_id" {
  type = string
}

variable "instance_id" {
  type = string
}
```

**`modulos/nlb/main.tf`**, agregar debajo del `aws_lb`:
```hcl
resource "aws_lb_target_group" "tg_web" {
  name     = "${local.nombre}-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener" "escucha_web" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_web.arn
  }
}

resource "aws_lb_target_group_attachment" "registro_web" {
  target_group_arn = aws_lb_target_group.tg_web.arn
  target_id        = var.instance_id
  port             = 80
}
```

**`main.tf` (raíz)**: `module "nlb"` queda así:
```hcl
module "nlb" {
  source = "./modulos/nlb"
  count  = length(var.cidr_subredes)

  prefijo     = local.prefijo
  nombre      = "nlb-${count.index}"
  subnet_id   = module.vpc.subnet_ids[count.index]
  vpc_id      = module.vpc.vpc_id
  instance_id = module.ec2[count.index].instance_id
}
```

**Probar:** abre `http://<nlb_dns>` (sale en `terraform output`). El target tarda 1 a 3 minutos en quedar *healthy* (EC2 → Target Groups → Targets).

---

### B5. for_each en vez de count (EC2)

Sirve si piden `for_each`, instancias con nombres propios o de distinto tamaño.

**`variables.tf` (raíz)**, agregar:
```hcl
variable "instancias" {
  type = map(object({
    subred = number
    tipo   = string
  }))
}
```

**`terraform.tfvars`**, agregar:
```hcl
instancias = {
  web = { subred = 0, tipo = "t3.micro" }
  app = { subred = 1, tipo = "t3.small" }
}
```

**`main.tf` (raíz)**: reemplaza `module "ec2"` completo por:
```hcl
module "ec2" {
  source   = "./modulos/ec2"
  for_each = var.instancias

  prefijo       = local.prefijo
  nombre        = each.key
  instance_type = each.value.tipo
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.subnet_ids[each.value.subred]
  ami_id        = var.ami_id
}
```

**`outputs.tf` (raíz)**: con `for_each` el splat `[*]` no funciona. Cambia el output de las IPs por:
```hcl
output "ec2_ips_publicas" {
  value = { for k, m in module.ec2 : k => m.public_ip }
}
```

`each.key` es `web` / `app`; `each.value.tipo` y `each.value.subred` vienen del map. Las referencias pasan a ser `module.ec2["web"]`.

> No lo combines con el agregado B4: el NLB está pensado para `count` (una EC2 por subred). Si piden ambos, deja `count` en EC2.

---

### B6. Validaciones y más outputs

**`variables.tf` (raíz)**: reemplaza las variables `proyecto` y `vpc_cidr` por:
```hcl
variable "proyecto" {
  type = string

  validation {
    condition     = length(var.proyecto) <= 10
    error_message = "El proyecto debe tener 10 caracteres o menos (nombre del NLB máx. 32)."
  }
}

variable "vpc_cidr" {
  type = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr debe ser un CIDR válido, ej: 10.0.0.0/16."
  }
}
```

**IP privada como output sensible.** En `modulos/ec2/outputs.tf`, agregar:
```hcl
output "private_ip" {
  value = aws_instance.servidor.private_ip
}
```
En `outputs.tf` (raíz), agregar:
```hcl
output "ec2_ips_privadas" {
  value     = module.ec2[*].private_ip
  sensitive = true
}
```

**Probar:** `terraform output` muestra `<sensitive>`, y `terraform output ec2_ips_privadas` muestra el valor. Para probar la validación, pon `proyecto = "nombremuylargo"` y ejecuta `plan`: debe aparecer tu `error_message`.

---

### B7. Módulo sg separado

Saca el security group de EC2 a su propio módulo. Se crea **1 SG compartido** por las 2 instancias.

**Crear `modulos/sg/variables.tf`:**
```hcl
variable "prefijo" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "puertos" {
  type = list(number)
}
```

**Crear `modulos/sg/main.tf`:**
```hcl
locals {
  nombre = "${var.prefijo}-sg"
}

resource "aws_security_group" "sg_web" {
  name   = local.nombre
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.puertos
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

**Crear `modulos/sg/outputs.tf`:**
```hcl
output "sg_id" {
  value = aws_security_group.sg_web.id
}
```

**`modulos/ec2/main.tf`**: borra el `resource "aws_security_group" "sg_ssh"` completo y en la instancia cambia:
```hcl
  vpc_security_group_ids = [var.sg_id]
```

**`modulos/ec2/variables.tf`**: cambia `variable "vpc_id"` por:
```hcl
variable "sg_id" {
  type = string
}
```

**`main.tf` (raíz)**: agrega el módulo antes de `module "ec2"`:
```hcl
module "sg" {
  source = "./modulos/sg"

  prefijo = local.prefijo
  vpc_id  = module.vpc.vpc_id
  puertos = var.puertos
}
```
Dentro de `module "ec2"`, cambia la línea `vpc_id = module.vpc.vpc_id` por:
```hcl
  sg_id     = module.sg.sg_id
```

**`variables.tf` (raíz)** y **`terraform.tfvars`**: agrega `puertos`, igual que en el agregado B3.

Al ser un módulo nuevo, **`terraform init`** antes del `validate`.

---

### B8. Route table "principal"

**`modulos/vpc/main.tf`**, agregar al final:
```hcl
resource "aws_route_table" "principal" {
  vpc_id = aws_vpc.vpc_principal.id
}
```
No se asocia a ninguna subred: las subredes públicas siguen usando `tabla_publica`.

---

### B9. Cambiar cantidades

Solo se cambia **`terraform.tfvars`**:
```hcl
cidr_subredes = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]   # 3 subredes → 3 EC2 y 3 NLB
buckets       = ["datos", "logs", "backup"]                       # 3 buckets
```
Hasta 4 subredes funciona sin problema. Desde la 5ª, la subred cae en `us-east-1e`, donde `t3.micro` no está disponible; en ese caso usa `instance_type = "t2.micro"`.
