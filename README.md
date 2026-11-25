# Apuntes Terraform: Infraestructura como Código I

## Contenido del repo

| Archivo / carpeta | Qué tiene |
|---|---|
| [`01-formativa2/`](01-formativa2/) | Formativa 2 resuelta: VPC, EC2, NLB, S3 (módulos, `remote-exec`, `local-exec`). Probada: 16 recursos |
| [`02-evaluacion2/`](02-evaluacion2/) | Evaluación 2 tal cual se entregó (nota 7.0): agrega RDS PostgreSQL y 3 subredes |
| [`03-formativa3/`](03-formativa3/) | Formativa 3 resuelta: Biblioteca Digital, `map(object)`, `for_each`, condicionales dev/prod, funciones |
| [`04-base-eva3/`](04-base-eva3/) | **Base para la Evaluación 3**: Formativa 3 + random, 2 locals por módulo, validación, `lookup` |
| [REGISTRY.md](REGISTRY.md) | Links del Terraform Registry + código estándar de cada recurso |
| [REPASO.md](REPASO.md) | Teoría corta de cada tema (count, for_each, módulos, funciones, condicionales…) |
| [AGREGADOS.md](AGREGADOS.md) | Lo que puede agregar el profe en la prueba, con el código listo |

**Índice de esta página**
1. [Cómo trabaja el profe](#1-cómo-trabaja-el-profe)
2. [Paso a paso para la prueba](#2-paso-a-paso-para-la-prueba)
3. [Comandos](#3-comandos)
4. [Debugging](#4-debugging)
5. [Learner Lab: preparación](#5-learner-lab-preparación)
6. [Orden para crear desde cero](#6-orden-para-crear-desde-cero)
7. [Errores comunes](#7-errores-comunes)

---

## 1. Cómo trabaja el profe

La prueba es **el ejercicio formativo anterior + agregados**. Ejemplo real:

| Formativa 2 | → Evaluación 2 (lo que agregó) |
|---|---|
| VPC, EC2, NLB, S3 | **+ RDS** PostgreSQL con versión específica |
| 2 subredes | **3 subredes** con otros CIDR, y cada recurso en una subred específica (EC2 en la 3ª, NLB en la 2ª) |
| random 6 caracteres | random **10** caracteres |
| 1 local por módulo | **2 locals por módulo** + comentario en la raíz indicando dónde están |
| `terraform.tfvars` | **`dev.tfvars`** (`-var-file`) |
| defaults permitidos | **sin defaults** |
| debugging | log con nombre **`su-nombre.log`** + documento Word con pantallazos |

➡️ Para la próxima prueba: partir de **[`04-base-eva3/`](04-base-eva3/)** (Formativa 3 con los agregados más probables ya aplicados). Otros agregados posibles en [AGREGADOS.md](AGREGADOS.md#parte-1-agregados-probables-sobre-la-formativa-3).

---

## 2. Paso a paso para la prueba

1. **Learner Lab → Start Lab** (esperar círculo verde).
2. Descargar el repo: **Code → Download ZIP → Extraer todo**.
3. Copiar la carpeta del ejercicio base a una carpeta nueva y abrirla en VS Code (**File → Open Folder**). Si aparece *Restricted Mode*: **Trust**.
4. **AWS Details → Download PEM** → `labsuser.pem` en la raíz del proyecto (junto a `main.tf`).
5. **AWS Details → AWS CLI → Show** → pegar en `C:\Users\<usuario>\.aws\credentials` → `aws sts get-caller-identity`.
6. Leer el enunciado completo y anotar cada requisito.
7. Ajustar el `.tfvars` (CIDR, cantidades, nombres, AMI) y agregar lo extra (ver [AGREGADOS.md](AGREGADOS.md)).
8. Activar debugging → `init` → `validate` → `plan` → `apply`.
9. Pantallazos: `plan`, `apply`, `output`, consola de AWS, archivo `.log`.
10. `destroy` cuando el profe lo autorice.

---

## 3. Comandos

Se ejecutan **en la carpeta donde está `main.tf`**.

```bash
terraform init                    # primero, y de nuevo si agregas módulo o provider
terraform fmt -recursive          # ordena el código
terraform validate                # revisa sintaxis
terraform plan
terraform apply                   # escribir: yes
terraform output
terraform destroy
```

**Con un archivo de variables distinto a `terraform.tfvars`** (ej. `dev.tfvars`):
```bash
terraform plan    -var-file="dev.tfvars"
terraform apply   -var-file="dev.tfvars"
terraform destroy -var-file="dev.tfvars"
```

**Cambiar una variable sin editar archivos** (ej. probar prod):
```bash
terraform plan -var="ambiente=prod"
```

**Probar funciones:** `terraform console` → `max(5, 12, 9)` → `exit`.

---

## 4. Debugging

Mira cómo empieza la línea de tu terminal en VS Code:

| Terminal | Activar | Desactivar |
|---|---|---|
| PowerShell (`PS C:\>`) | `$env:TF_LOG="DEBUG"`<br>`$env:TF_LOG_PATH="rodrigo.log"` | `Remove-Item Env:TF_LOG, Env:TF_LOG_PATH` |
| CMD (`C:\>`) | `set TF_LOG=DEBUG`<br>`set TF_LOG_PATH=rodrigo.log` | `set TF_LOG=`<br>`set TF_LOG_PATH=` |
| Git Bash (`$`) | `export TF_LOG=DEBUG`<br>`export TF_LOG_PATH=./rodrigo.log` | `unset TF_LOG TF_LOG_PATH` |

- Niveles: `TRACE` (máximo) → `DEBUG` → `INFO` → `WARN` → `ERROR`.
- Solo funciona en esa terminal. Activarlo **antes** del `plan` / `apply` para que el `.log` tenga todo.
- Verificar: `echo $env:TF_LOG` (PowerShell).

---

## 5. Learner Lab: preparación

- [ ] **Credenciales** en `C:\Users\<usuario>\.aws\credentials` (archivo **sin extensión**; crear carpeta `.aws` si no existe). Vencen al apagar el lab: si sale `ExpiredToken`, se copian de nuevo.
- [ ] `aws sts get-caller-identity` → debe mostrar tu `Account`.
- [ ] Si sale `Unknown output type: Json` → `aws configure set output json`.
- [ ] `labsuser.pem` en la raíz del proyecto (solo para SSH / `remote-exec`).
- [ ] Región `us-east-1`, key pair `vockey`.

**ID de la AMI (Amazon Linux 2023):**
```powershell
aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-2023*-x86_64" --query "sort_by(Images,&CreationDate)[-1].ImageId" --output text
```
O en la consola: EC2 → Launch instance → Amazon Linux 2023 → copiar `ami-0...`.

**SSH a una instancia:**
```powershell
ssh -i labsuser.pem ec2-user@<IP_PUBLICA>
```

**VS Code sin colores / todo en rojo:** confiar en la carpeta (`Ctrl+Shift+P` → *Manage Workspace Trust* → **Trust**) y hacer `terraform init`. Si `terraform validate` dice *Success*, el código está bien aunque el editor marque rojo.

---

## 6. Orden para crear desde cero

Dentro de cada módulo siempre: **`variables.tf` → `main.tf` → `outputs.tf`**.

1. Carpetas: `modulos/vpc`, `modulos/ec2`, `modulos/nlb`, `modulos/s3`, `modulos/rds`.
2. Raíz: `providers.tf` → `variables.tf` → `.tfvars` → `main.tf` (random + locals) → `terraform init`.
3. Módulo **VPC** primero (los demás usan sus outputs) → `module "vpc"` en la raíz → `init` → `validate`.
4. **EC2** → **NLB** → **RDS** → **S3** (mismo orden interno) → `init` + `validate` después de cada uno.
5. `outputs.tf` raíz.
6. Debugging → `plan` → `apply`.

**Reglas:**
- Agregas un `module` → `terraform init`.
- Pasas un valor a un módulo → declararlo en su `variables.tf`.
- La raíz lee `module.x.algo` → declararlo en el `outputs.tf` del módulo.

**Estructura:**
```
proyecto/
├── labsuser.pem        ← llave suelta en la raíz
├── providers.tf
├── variables.tf
├── dev.tfvars          ← o terraform.tfvars
├── main.tf
├── outputs.tf
└── modulos/
    ├── vpc/ (variables.tf, main.tf, outputs.tf)
    ├── ec2/ ...
    └── ...
```

---

## 7. Errores comunes

| Error | Solución |
|---|---|
| `No configuration files` | Estás en otra carpeta → `cd` a donde está `main.tf` |
| `Module not installed` / `provider not installed` | `terraform init` |
| `No valid credential sources` / `ExpiredToken` | Copiar credenciales de nuevo (archivo sin `.txt`) |
| `Unknown output type: Json` | `aws configure set output json` |
| `InvalidAMIID.Malformed` / `NotFound` | AMI mal copiada o de otra región |
| `Invalid function argument` (pem) | `labsuser.pem` no está junto a `main.tf` |
| `remote-exec` en *Still creating...* | Falta IGW, ruta `0.0.0.0/0`, IP pública o puerto 22 |
| `cannot be longer than 32 characters` | Nombre de NLB / target group muy largo → acortar `proyecto` |
| `BucketAlreadyExists` / nombre inválido | Nombre único en el mundo; solo minúsculas, números y guiones |
| `has no internet gateway` | El NLB se creó antes que el IGW → `depends_on` (ya incluido en los ejercicios) |
| `Reference to undeclared input variable` | Pasaste a un módulo algo que no está en su `variables.tf` |
| `Unsupported attribute` en `module.x.y` | El output `y` no existe en el módulo |
| `Missing required argument` | Variable sin valor: falta en el `.tfvars` o falta pasarla al módulo |
| Pide valores por consola en el `plan` | Variable declarada sin valor en el `.tfvars` (o falta `-var-file`) |
| `Invalid for_each argument` | Las **claves** del map/set no se conocen antes del apply |
| `Error acquiring the state lock` | `terraform force-unlock <ID>` |
| `UnauthorizedOperation` / `AccessDenied` | El Learner Lab no permite ese recurso o tamaño |

**Plan B:** si algo falla y no sabes dónde, comenta los módulos (`Ctrl + K, Ctrl + C`) y actívalos de a uno.
