# Base para la Evaluación 3

Es la **Formativa 3 con los agregados más probables ya aplicados**, siguiendo el patrón del profe (lo que agregó de la Formativa 2 a la Evaluación 2). Mañana se parte de aquí y solo se agrega lo nuevo que pida el enunciado.

La Formativa 3 original sigue intacta en [`03-formativa3/`](../03-formativa3/).

## Qué tiene además de la Formativa 3

| Agregado | Dónde |
|---|---|
| **`random_string` de 10 caracteres** en el `locals` (nombre del bucket) | `main.tf` raíz + provider `random` en `providers.tf` |
| **2 locals en cada módulo** + comentario en la raíz indicando dónde están | Cada `modulos/*/main.tf` |
| **Validación de `ambiente`** (solo `dev` o `prod`) | `variables.tf` raíz |
| **`lookup`**: clase de la RDS según el ambiente | `db_clase = { dev = ..., prod = ... }` en `terraform.tfvars` |
| **`length` y `keys`** en outputs | `outputs.tf` raíz |
| Comentario en la raíz con **funciones y condicionales** usados | Inicio de `main.tf` raíz |

Si el profe pide un número distinto de caracteres para el random, se cambia `length` en `main.tf` raíz.

**Locals por módulo:**

| Módulo | Locals |
|---|---|
| raíz | `nombre`, `bucket`, `tags` |
| vpc | `nombre_vpc`, `publicas` |
| ec2 | `nombre_sg`, `factor` (condicional disco x2) |
| nlb | `nombre_nlb`, `nombre_tg` |
| rds | `nombre_db`, `motor` |
| s3 | `nombre_bucket`, `estado` (condicional versionado) |

**Funciones:** `format`, `merge`, `lookup`, `length`, `keys`.
**Condicionales:** discos x2 (ec2), Multi-AZ (rds), versionado (s3).

## Ejecutar
```powershell
$env:TF_LOG="DEBUG"
$env:TF_LOG_PATH="rodrigo.log"
terraform init
terraform validate
terraform plan
terraform apply
terraform output
terraform plan -var="ambiente=prod"   # verificar condicionales, SIN apply
terraform destroy
```
Para probar prod también puedes cambiar `ambiente = "prod"` en `terraform.tfvars`, hacer `plan` (sin apply) y volver a dejarlo en `"dev"`.

Si el profe pide un archivo `dev.tfvars`: renombra `terraform.tfvars` → `dev.tfvars` y agrega `-var-file="dev.tfvars"` a `plan`, `apply` y `destroy` (ver [AGREGADOS.md](../AGREGADOS.md#a2-devtfvars-y-prodtfvars)).

**Qué cambia en el plan de prod:** `multi_az = true`, discos 60 / 60 / 120, versionado `Enabled`, RDS `db.t3.small` y nombres con `-prod-`.

## Validación (Etapa 3)
Igual que en la Formativa 3: ver [su README](../03-formativa3/README.md#etapa-3-validación) (NLB en el navegador, SSH + mysql, archivo en S3).

## Antes de usarla
- Revisar `ami_id` en `terraform.tfvars`.
- Si `aws_s3_bucket` falla en el Learner Lab: [plan B en AGREGADOS.md](../AGREGADOS.md#plan-b-s3-con-local-exec).
- Otros agregados posibles (`count ? 1 : 0`, `dynamic`, varios buckets): [AGREGADOS.md, parte 1](../AGREGADOS.md#parte-1-agregados-probables-sobre-la-formativa-3).
