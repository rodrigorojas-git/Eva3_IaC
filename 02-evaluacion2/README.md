# Evaluación 2: VPC + EC2 + NLB + S3 + RDS (nota 7.0)

Código **tal cual se entregó**. Es la Formativa 2 con los agregados del profe.

## Enunciado (resumen)
- Módulos `vpc`, `ec2`, `nlb`, `s3`, **`rds`**, con al menos **2 valores** pasados desde la raíz a cada uno.
- 1 VPC `10.0.0.0/16` con **3 subredes públicas**: `10.0.15.0/24`, `10.0.25.0/24`, `10.0.35.0/24`.
- **3 EC2 en la tercera subred**, **2 NLB en la segunda subred**, **3 S3** privados.
- **1 RDS PostgreSQL 18.3**.
- `random` de **10 caracteres** en `locals`; al menos 2 locals en todos los módulos.
- `count` / `for_each`, **sin defaults** en las variables.
- Debugging guardado en **`su-nombre.log`**.
- Archivo `dev.tfvars` con los valores de la raíz.
- Entregables: ZIP con los `.tf`, el `.tfvars`, el `.log` y un Word con los pantallazos del paso a paso.

## Ejecutar
```powershell
$env:TF_LOG="DEBUG"
$env:TF_LOG_PATH="rodrigo.log"
terraform init
terraform validate
terraform plan
terraform apply
terraform output
terraform destroy
```
- Al hacer `plan` / `apply`, Terraform pide por consola `var.nombre` y `var.prefijo` (están declaradas en `variables.tf` raíz sin valor en el tfvars). Escribe cualquier texto y Enter.
- La RDS tarda entre 5 y 10 minutos en crearse.
- Si te piden el archivo `dev.tfvars`: renombra `terraform.tfvars` a `dev.tfvars` y agrega `-var-file="dev.tfvars"` a `plan`, `apply` y `destroy`.

## Dónde se cumple cada requisito

| Requisito | Dónde |
|---|---|
| 3 subredes con los CIDR pedidos | `terraform.tfvars` → `cidr_subredes`; `modulos/vpc` las crea con `count` |
| 3 EC2 en la **tercera** subred | `subnet_id = module.vpc.subnet_ids[2]` en `module "ec2"` |
| 2 NLB en la **segunda** subred | `subnet_id = module.vpc.subnet_ids[1]` en `module "nlb"` |
| Cantidades por variable | `cantidad_ec2 = 3`, `cantidad_nlb = 2` → `count` en los módulos |
| 3 S3 privados | `buckets = ["datos", "logs", "backups"]` → `for_each` + `local-exec` |
| RDS PostgreSQL 18.3 | `modulos/rds`: subnet group (3 subredes), SG 5432 desde la VPC, `aws_db_instance` |
| random 10 caracteres en locals | `main.tf` raíz → `local.prefijo` |
| ≥2 valores a cada módulo | vpc 3, ec2 6, nlb 3, s3 3, rds 9 |
| Sin defaults | Ninguna variable tiene `default` |
| Password protegida | `db_password` con `sensitive = true` (raíz y módulo) |
| Debugging | `rodrigo.log` |

**Locals por módulo:**

| Módulo | Locals |
|---|---|
| raíz | `prefijo`, `nombre` |
| vpc | `nombre` |
| ec2 | `nombre` |
| nlb | `nombre` |
| s3 | `nombre`, `region` |
| rds | `nombre` |
