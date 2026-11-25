# Formativa 3: Biblioteca Digital (EduAndes)

Base para la próxima evaluación. Temas nuevos: **funciones integradas** y **condicionales**.

## Enunciado (resumen)
- VPC con **4 subredes** (2 públicas, 2 privadas) **sin repetir bloques**.
- Servidores en **una variable `map(object)`** (tipo de instancia + disco) y creados con **un solo bloque `for_each`**:

  | Servidor | Tipo | Disco |
  |---|---|---|
  | biblioteca-a | t3.medium | 30 GB |
  | biblioteca-b | t3.medium | 30 GB |
  | biblioteca-c (reportes) | t3.large | 60 GB |
- **NLB** + target group + listener TCP; registrar los servidores con un **ciclo**.
- **RDS MySQL** en las subredes privadas, sin acceso desde internet, solo desde los servidores (por SG); password `sensitive`.
- **S3** con nombre armado con **`format()`**.
- Al menos **2 funciones** internas; **`locals`** con tags comunes aplicados con **`merge()`**.
- Variable **`ambiente`** (`dev` / `prod`) con condicionales: en prod la RDS es **Multi-AZ**, los discos **se duplican** y el bucket tiene **versionado**.
- Outputs: DNS del NLB, endpoint de la RDS y nombre del bucket.

## Estructura
```
03-formativa3/
├── providers.tf
├── variables.tf
├── terraform.tfvars   ← lo único que se cambia
├── main.tf            ← locals + 5 módulos
├── outputs.tf
└── modulos/
    ├── vpc/  VPC, IGW, 4 subredes (for_each), route table
    ├── ec2/  SG + servidores (for_each)
    ├── nlb/  NLB, target group, listener, targets (for_each)
    ├── rds/  subnet group, SG, MySQL
    └── s3/   bucket + versionado
```

## Cómo se conectan los módulos
```
vpc ──vpc_id, subred_ids──────────► ec2 ──instancia_ids──► nlb
    ──subredes_publicas───────────────────────────────────► nlb
    ──subredes_privadas───► rds ◄──sg_id── ec2
s3 (recibe el nombre del bucket y el ambiente)
```
La raíz arma `local.nombre`, `local.bucket` y `local.tags` y se los pasa a todos.

## Dónde se cumple cada requisito

| Requisito | Dónde |
|---|---|
| 4 subredes sin repetir bloques | `modulos/vpc`: un `aws_subnet` con `for_each = var.subredes` |
| Servidores en `map(object)` | `var.servidores`: `{ tipo, disco, subred }` |
| 3 instancias con un solo bloque | `modulos/ec2`: `aws_instance` con `for_each` |
| 4º servidor = una línea | Agregar una entrada al mapa `servidores` en el tfvars |
| NLB + TG + listener TCP + targets en ciclo | `modulos/nlb` (attachment con `for_each`) |
| RDS privada, solo desde servidores | `modulos/rds`: `publicly_accessible = false`, SG con `security_groups = [sg de servidores]` |
| Password `sensitive` | `db_password` (raíz) y `password` (módulo rds) |
| Bucket con `format()` | `main.tf` raíz → `local.bucket` |
| Funciones | **`format`** (nombres) y **`merge`** (tags) |
| Tags comunes con `merge()` | `local.tags` → `merge(var.tags, { Name = ... })` en cada recurso |
| Condicional discos x2 | `modulos/ec2/main.tf` |
| Condicional Multi-AZ | `modulos/rds/main.tf` |
| Condicional versionado | `modulos/s3/main.tf` |

**Extras necesarios para la Etapa 3:** `user_data` (Apache + cliente mysql), SG con 22 y 80, `force_destroy` en el bucket, `depends_on` para que el NLB espere al IGW, y output `ips_servidores` para el SSH.

## Etapa 3: validación
```powershell
terraform init
terraform plan
terraform apply
```
1. **NLB:** abrir `http://<nlb_dns>` (esperar 2-3 min a que los targets estén *healthy*).
2. **RDS desde un servidor:**
   ```powershell
   ssh -i labsuser.pem ec2-user@<ip de biblioteca-a>
   mysql -h <rds_endpoint sin :3306> -u admin -p
   ```
   Desde tu PC **no** debe conectar: `Test-NetConnection <endpoint> -Port 3306` → falla.
3. **S3:**
   ```powershell
   echo "hola" > prueba.txt
   aws s3 cp prueba.txt s3://<bucket>/
   aws s3 ls s3://<bucket>/
   ```
4. **Prod sin apply:** `terraform plan -var="ambiente=prod"` → `multi_az = true`, discos 60/60/120, versionado `Enabled`.
5. `terraform destroy`

**Notas:** la RDS tarda 5-10 min. Si `aws_s3_bucket` falla en el Learner Lab, ver [AGREGADOS.md](../AGREGADOS.md#plan-b-s3-con-local-exec).
