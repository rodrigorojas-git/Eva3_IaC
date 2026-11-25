# Formativa 2: VPC + EC2 + NLB + S3

**Probada en el Learner Lab:** `apply` con 16 recursos, outputs correctos y `destroy` completo.

## Enunciado (resumen)
- Módulos `vpc`, `ec2`, `nlb`, `s3` con `main.tf`, `variables.tf`, `outputs.tf`.
- 1 VPC `10.0.0.0/16` con subredes `10.0.1.0/24` y `10.0.2.0/24`.
- 2 EC2 y 2 NLB en las subredes del módulo VPC, 2 S3 privados.
- Variables y outputs en raíz e hijos, `random` de 6 caracteres en `locals`, `locals` en todos los módulos, `count` / `for_each`, debugging.
- Tópicos: funciones repetitivas, variables y outputs, módulos, debugging, locals, `remote-exec`, `local-exec`.

## Qué crea
VPC, IGW, 2 subredes públicas, route table + asociaciones, 2 EC2 (con `remote-exec`), 2 NLB y 2 buckets S3 privados (con `local-exec`, porque en el Learner Lab `aws_s3_bucket` no funcionó).

## Ejecutar
1. `labsuser.pem` en esta carpeta.
2. Revisar `ami_id` en `terraform.tfvars`.
3. Debugging → `terraform init` → `validate` → `plan` → `apply` → `output` → `destroy`.

## Dónde se cumple cada requisito

| Requisito | Dónde |
|---|---|
| Variables / outputs en raíz e hijos | `variables.tf` / `outputs.tf` de cada carpeta |
| `random` 6 caracteres en `locals` | `main.tf` raíz → `local.prefijo` |
| `locals` en todos los módulos | `local.nombre` en cada `modulos/*/main.tf` |
| `count` / `for_each` | `count`: subredes, EC2, NLB · `for_each`: S3 |
| `remote-exec` / `local-exec` | `modulos/ec2` / `modulos/s3` |
| AMI por variable (raíz → hijo → tfvars) | `ami_id` en `variables.tf`, `module "ec2"` y `terraform.tfvars` |

**Nombres de los recursos.** Cada nombre se usa solo dentro de su módulo, en su `main.tf` y su `outputs.tf`.

| Módulo | Recurso | Se referencia como |
|---|---|---|
| vpc | `aws_vpc "vpc_principal"` | `aws_vpc.vpc_principal.id` |
| vpc | `aws_internet_gateway "igw"` | `aws_internet_gateway.igw.id` |
| vpc | `aws_subnet "subred_publica"` | `aws_subnet.subred_publica[0].id` |
| vpc | `aws_route_table "tabla_publica"` | `aws_route_table.tabla_publica.id` |
| vpc | `aws_route_table_association "asociacion_publica"` | — |
| ec2 | `aws_security_group "sg_ssh"` | `aws_security_group.sg_ssh.id` |
| ec2 | `aws_instance "servidor"` | `aws_instance.servidor.public_ip` |
| nlb | `aws_lb "nlb"` | `aws_lb.nlb.dns_name` |
| s3 | `null_resource "bucket_privado"` | `null_resource.bucket_privado` |

Para renombrar: cambia el nombre y todas sus referencias del mismo módulo (`Ctrl + Shift + H` en VS Code). La raíz no se toca porque usa los outputs (`module.ec2[0].public_ip`).


## Qué cambiar según lo que pidan

| Si piden... | Cambiar |
|---|---|
| Otros CIDR / más subredes | `terraform.tfvars` → `vpc_cidr`, `cidr_subredes` (EC2 y NLB se crean uno por subred) |
| Más o menos buckets | `terraform.tfvars` → `buckets` |
| Otro nombre | `terraform.tfvars` → `proyecto` (corto, el NLB admite máx. 32 caracteres) |
| Otra AMI | `terraform.tfvars` → `ami_id` (si es Ubuntu: `user = "ubuntu"` y `apt`) |
| Otro tipo de EC2 | En `module "ec2"`: `instance_type = "t3.small"` |
| Abrir puerto 80 | Copiar el bloque `ingress` en `modulos/ec2/main.tf` con `80` |
| Instalar algo en EC2 | `inline` de `remote-exec`: `"sudo dnf install -y httpd"`, `"sudo systemctl enable --now httpd"` |
| ALB en vez de NLB | [REGISTRY.md](../REGISTRY.md#alb) → ALB (2 subredes + SG) |
| Conectar LB con EC2 | [REGISTRY.md](../REGISTRY.md#target-group--listener--attachment) → target group + listener + attachment |
| Route table "principal" | En `modulos/vpc/main.tf`: `resource "aws_route_table" "principal" { vpc_id = aws_vpc.vpc_principal.id }` |
| `for_each` en módulos | [AGREGADOS.md](../AGREGADOS.md#b5-for_each-en-vez-de-count-ec2) |

