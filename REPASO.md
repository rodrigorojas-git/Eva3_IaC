# Repaso de teoría

1. [count / for_each / for](#count--for_each--for)
2. [Variables y outputs](#variables-y-outputs)
3. [Módulos](#módulos)
4. [Locals](#locals)
5. [Provisioners](#provisioners)
6. [Funciones integradas](#funciones-integradas)
7. [Condicionales](#condicionales)
8. [Debugging](#debugging)
9. [Cómo fluye un valor (ej. Formativa 3)](#cómo-fluye-un-valor)

---

## count / for_each / for
🔗 https://developer.hashicorp.com/terraform/language/meta-arguments/count
🔗 https://developer.hashicorp.com/terraform/language/meta-arguments/for_each
```hcl
count    = 2                          # count.index → 0, 1 · ref: recurso[0], recurso[*].id
for_each = toset(["a", "b"])          # each.key    · ref: recurso["a"]
for_each = { a = "10.0.1.0/24" }      # each.key, each.value
lista    = [for x in var.lista : upper(x)]
```
`count` usa índices: si borras uno del medio, se recrean los siguientes. `for_each` usa claves: solo se borra ese.

## Variables y outputs
🔗 https://developer.hashicorp.com/terraform/language/values/variables
```hcl
variable "ambiente" {
  type    = string                    # string, number, bool, list(string), set(string), map(string)
  default = "dev"
  validation {
    condition     = contains(["dev", "prod"], var.ambiente)
    error_message = "Debe ser dev o prod."
  }
}

output "ips" {
  value     = module.ec2[*].public_ip
  sensitive = false                   # true = la oculta en pantalla (igual queda en el state)
}
```
Precedencia (gana el último): default → `TF_VAR_x` → `terraform.tfvars` → `*.auto.tfvars` → `-var`.

## Módulos
🔗 https://developer.hashicorp.com/terraform/language/modules/syntax
```hcl
module "vpc" {
  source   = "./modulos/vpc"
  vpc_cidr = var.vpc_cidr             # variable declarada en modulos/vpc/variables.tf
}
# leer un output del hijo: module.vpc.vpc_id

module "ec2" {                        # versión con for_each
  source    = "./modulos/ec2"
  for_each  = { web0 = 0, web1 = 1 }
  nombre    = each.key
  subnet_id = module.vpc.subnet_ids[each.value]
  # ...resto de argumentos
}
# output: { for k, m in module.ec2 : k => m.instance_id }
```

## Locals
```hcl
locals {
  nombre = "${var.prefijo}-${var.nombre}"
}
# uso: local.nombre
```
Variable = viene de afuera. Local = valor calculado interno.

## Provisioners
🔗 https://developer.hashicorp.com/terraform/language/provisioners
```hcl
resource "aws_instance" "servidor" {
  # ...
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("labsuser.pem")
    host        = self.public_ip
  }

  provisioner "remote-exec" {          # corre DENTRO de la instancia
    inline = ["sudo dnf install -y httpd", "sudo systemctl enable --now httpd"]
  }

  provisioner "local-exec" {           # corre en TU máquina
    command = "echo ${self.public_ip} >> ips.txt"
  }
}
```
- `remote-exec` necesita: IP pública, IGW + ruta, puerto 22 abierto, key pair y `connection`.
- `when = destroy`: se ejecuta al destruir.
- `on_failure = continue`: no se detiene si falla (por defecto falla y el recurso queda *tainted*).

## Funciones integradas
🔗 https://developer.hashicorp.com/terraform/language/functions

Vienen incluidas en Terraform; no se declaran. Se prueban en `terraform console` (sales con `exit`).

| Tipo | Función | Ejemplo | Resultado |
|---|---|---|---|
| String | `split` | `split(" ", "Esto es un ejemplo")` | `["Esto","es","un","ejemplo"]` |
| String | `join` | `join(" ", ["Esto","es"])` | `"Esto es"` |
| String | `replace` | `replace("Password@123", "a", "@")` | `"P@ssword@123"` |
| String | `format` | `format("%s-%s", "eduandes", "dev")` | `"eduandes-dev"` |
| String | `upper` / `lower` | `upper("web")` | `"WEB"` |
| Numeric | `max` / `min` | `max(5, 12, 9)` | `12` |
| Collection | `length` | `length("hello")` | `5` |
| Collection | `concat` | `concat(["a"], ["b","c"])` | `["a","b","c"]` |
| Collection | `sort` | `sort(["e","d","a"])` | `["a","d","e"]` |
| Collection | `merge` | `merge({a="b", c="d"}, {c="z"})` | `{a="b", c="z"}` (gana el último) |
| Collection | `lookup` | `lookup({dev="t3.micro"}, "prod", "t3.small")` | `"t3.small"` (default si no existe la clave) |
| Collection | `keys` / `values` | `keys({a=1, b=2})` | `["a","b"]` |
| Collection | `toset` | `toset(["a","a","b"])` | `["a","b"]` (sin duplicados) |
| Collection | `contains` | `contains(["dev","prod"], "dev")` | `true` |
| IP | `cidrsubnet` | `cidrsubnet("10.0.0.0/16", 8, 1)` | `"10.0.1.0/24"` |

**format:** `%s` = texto, `%d` = número, `%02d` = número con 2 dígitos (`01`).

**Uso en la Formativa 3:**
```hcl
nombre = format("%s-%s-%s", var.proyecto, var.aplicacion, var.ambiente) # "eduandes-biblioteca-dev"
tags   = merge(var.tags, { Name = "${var.nombre}-vpc" })               # tags comunes + Name
```

## Condicionales
🔗 https://developer.hashicorp.com/terraform/language/expressions/conditionals

```
condicion ? valor_si_verdadero : valor_si_falso
```

**1. Elegir un valor**
```hcl
instance_type = var.ambiente == "prod" ? "t3.large" : "t3.micro"
volume_size   = var.ambiente == "prod" ? each.value.disco * 2 : each.value.disco
status        = var.ambiente == "prod" ? "Enabled" : "Suspended"
```

**2. Devolver true/false directo** (la comparación ya es un bool)
```hcl
multi_az = var.ambiente == "prod"
```

**3. Crear o no un recurso** (`count` 1 o 0)
```hcl
count = var.crear_rds ? 1 : 0
# referencia: modulo/recurso[0]  ·  output protegido:
value = var.crear_rds ? module.rds[0].endpoint : "no creada"
```

- Operadores: `==` `!=` `>` `<` `>=` `<=` `&&` (y) `||` (o) `!` (no).
- Los dos valores deben ser del **mismo tipo**.
- Cambiar de ambiente = cambiar **solo la variable** (`.tfvars` o `-var="ambiente=prod"`).

## Debugging
🔗 https://developer.hashicorp.com/terraform/internals/debugging

| Nivel | Uso |
|---|---|
| `TRACE` | Máximo detalle (llamadas a la API) |
| `DEBUG` | Diagnosticar config/provider |
| `INFO` | Flujo general |
| `WARN` | Advertencias |
| `ERROR` | Solo errores |

`TF_LOG` activa el log y `TF_LOG_PATH` lo guarda en un archivo. Comandos por terminal en el [README](README.md#4-debugging).

## Cómo fluye un valor

```
terraform.tfvars ─► variables.tf (raíz) ─► main.tf (raíz) ─► module "x" { arg = ... }
                                                                    │
                                     modulos/x/variables.tf ◄───────┘  (entra)
                                     modulos/x/main.tf        (se usa: var.arg)
                                     modulos/x/outputs.tf ───► module.x.salida (sale)
```
- **Entra** a un módulo por sus `variables`; **sale** por sus `outputs`.
- Un módulo usa el output de otro así: `vpc_id = module.vpc.vpc_id` (dependencia implícita: primero se crea la VPC).
