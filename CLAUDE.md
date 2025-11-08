# 🤖 CLAUDE.md - Contexto Terraform Robotia Intranet

## 📋 Información del Proyecto

**Nombre:** Robotia Intranet Terraform
**Tipo:** Infrastructure as Code (IaC) con Terraform para GCP
**Estado:** Producción (desarrollo activo)
**Última actualización:** 2025-11-08
**Mantenedor:** Camilo González (@camiloengineer.com)
**Repositorio:** https://github.com/camiloengineer/intranet-robotia-terraform

---

## 🏗️ Arquitectura

### Stack Tecnológico
- **IaC:** Terraform >= 1.0
- **Provider:** Google Cloud Platform (hashicorp/google ~> 6.0)
- **Backend:** Google Cloud Storage (GCS)
- **Infraestructura:** Compute Engine + Firewall + Storage

### Recursos Gestionados

| Recurso | Nombre | Descripción |
|---------|--------|-------------|
| `google_compute_instance` | wordpress | e2-micro, Debian 12, LAMP stack |
| `google_compute_firewall` | allow-http | HTTP (80) |
| `google_compute_firewall` | allow-https | HTTPS (443) |
| `google_storage_bucket` | backups | Backups con lifecycle 90 días |
| `google_storage_bucket` | terraform_state | State remoto con versionado |

---

## 📁 Estructura del Proyecto

```
intranet-robotia-terraform/
├── backend.tf                  # Config backend GCS
├── main.tf                     # Recursos principales
├── variables.tf                # Variables configurables
├── outputs.tf                  # Outputs útiles
├── install-wordpress.sh        # Startup script (metadata)
├── .gitignore                  # Exclusiones (state, tfvars)
├── README.md                   # Quick start + usage
├── TERRAFORM.md                # Arquitectura detallada
└── CLAUDE.md                   # Este archivo
```

---

## 🚀 Workflow de Desarrollo

### Inicialización (Una sola vez)

```bash
# 1. Clonar repositorio
git clone git@github.com:camiloengineer/intranet-robotia-terraform.git
cd intranet-robotia-terraform

# 2. Crear bucket para state (si no existe)
gsutil mb -p intranet-robotia -c STANDARD -l us-central1 gs://robotia-terraform-state
gsutil versioning set on gs://robotia-terraform-state

# 3. Inicializar Terraform
terraform init

# 4. Ver estado actual
terraform show
```

### Flujo de Cambios

```bash
# 1. Editar archivos .tf
vim main.tf

# 2. Formatear código
terraform fmt

# 3. Validar sintaxis
terraform validate

# 4. Ver plan (diff)
terraform plan

# 5. Aplicar cambios
terraform apply

# 6. Ver outputs
terraform output
```

### Comandos Útiles

```bash
# Ver state completo
terraform show

# Ver solo outputs
terraform output

# Ver un output específico
terraform output instance_public_ip

# Listar recursos en state
terraform state list

# Ver detalles de un recurso
terraform state show google_compute_instance.wordpress

# Importar recurso existente
terraform import google_compute_instance.wordpress intranet-robotia/us-central1-a/intranet-robotia

# Destruir TODO (¡CUIDADO!)
terraform destroy

# Destruir solo un recurso
terraform destroy -target=google_compute_instance.wordpress
```

---

## 📊 Variables Importantes

### Variables con Defaults

```hcl
variable "project_id" { default = "intranet-robotia" }
variable "region" { default = "us-central1" }
variable "zone" { default = "us-central1-a" }
variable "machine_type" { default = "e2-micro" }
variable "instance_name" { default = "intranet-robotia" }
variable "boot_disk_size" { default = 20 }
```

### Override de Variables

```bash
# Opción 1: CLI
terraform apply -var="machine_type=e2-small"

# Opción 2: archivo terraform.tfvars
cat > terraform.tfvars <<EOF
machine_type = "e2-small"
boot_disk_size = 30
EOF

terraform apply
```

---

## 🔄 Backend State Management

### Ubicación del State

```
gs://robotia-terraform-state/terraform/state/default.tfstate
```

### Ver State Remoto

```bash
# Listar versiones
gsutil ls -a gs://robotia-terraform-state/terraform/state/

# Descargar state actual
gsutil cp gs://robotia-terraform-state/terraform/state/default.tfstate ./terraform.tfstate.backup
```

### Recuperar State Anterior

```bash
# Listar versiones con timestamps
gsutil ls -L gs://robotia-terraform-state/terraform/state/

# Restaurar versión específica
gsutil cp gs://robotia-terraform-state/terraform/state/default.tfstate#1234567890 \
  gs://robotia-terraform-state/terraform/state/default.tfstate
```

---

## 🧩 Recursos Terraform

### 1. Compute Instance (main.tf:15-54)

```hcl
resource "google_compute_instance" "wordpress" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  metadata_startup_script = file("${path.module}/install-wordpress.sh")
  ...
}
```

**Características:**
- Debian 12 (debian-cloud/debian-12)
- e2-micro (free tier)
- IP pública ephemeral
- Startup script automático
- Labels para tracking

### 2. Firewall Rules (main.tf:62-94)

```hcl
resource "google_compute_firewall" "allow_http" {
  ports = ["80"]
  target_tags = ["http-server"]
}

resource "google_compute_firewall" "allow_https" {
  ports = ["443"]
  target_tags = ["https-server"]
}
```

### 3. Storage Buckets (main.tf:100-148)

```hcl
resource "google_storage_bucket" "backups" {
  lifecycle_rule {
    condition { age = 90 }
    action { type = "Delete" }
  }
}

resource "google_storage_bucket" "terraform_state" {
  versioning { enabled = true }
}
```

---

## 🔐 Seguridad

### Secretos NO en Terraform

**❌ NUNCA hacer:**
```hcl
variable "db_password" {
  default = "wppass123"  # Visible en state!
}
```

**✅ Usar GCP Secret Manager:**
```bash
# Leer secreto en runtime
data "google_secret_manager_secret_version" "db_password" {
  secret = "DB_PASSWORD"
}
```

### State Sensible

El Terraform state contiene:
- IPs públicas
- Configuraciones de red
- Metadata de recursos

**Protección:**
- ✅ State en GCS (no en Git)
- ✅ Versionado habilitado
- ✅ Bucket privado (uniform access)

### .gitignore

```
*.tfstate
*.tfstate.*
*.tfvars
.terraform/
```

---

## 🐛 Troubleshooting

### Error: Backend bucket no existe

```bash
# Crear bucket
gsutil mb -p intranet-robotia -c STANDARD -l us-central1 gs://robotia-terraform-state
gsutil versioning set on gs://robotia-terraform-state
```

### Error: Permisos insuficientes

```bash
# Verificar permisos
gcloud projects get-iam-policy intranet-robotia

# Roles necesarios:
# - roles/compute.admin
# - roles/storage.admin
# - roles/compute.networkAdmin
```

### Error: Resource already exists

```bash
# Importar recurso existente al state
terraform import google_compute_instance.wordpress \
  projects/intranet-robotia/zones/us-central1-a/instances/intranet-robotia
```

### Startup script falló

```bash
# SSH a instancia
gcloud compute ssh intranet-robotia --zone=us-central1-a

# Ver logs
sudo journalctl -u google-startup-scripts.service

# Ver output del script
sudo cat /var/log/syslog | grep startup-script
```

---

## 🎯 INSTRUCCIONES PARA CLAUDE CODE

### Principios DRY

1. ✅ **SIEMPRE usar variables** - No hardcodear valores
2. ✅ **Outputs útiles** - Comandos copy-paste ready
3. ✅ **Documentación inline** - Comments en código complejo

### Antes de modificar código

1. ✅ Lee CLAUDE.md (este archivo) y TERRAFORM.md
2. ✅ Ejecuta `terraform validate`
3. ✅ Ejecuta `terraform plan` antes de `apply`
4. ✅ Verifica que no haya secretos hardcodeados
5. ✅ Formatea con `terraform fmt`

### Reglas de Commits

- ✅ **SIEMPRE** haz `terraform plan` antes de commit
- ✅ **NUNCA** commitees `*.tfstate*` o `*.tfvars`
- ✅ **NUNCA** commitees directorio `.terraform/`
- ✅ **SIEMPRE** usa mensajes descriptivos

```bash
# ❌ MAL
git commit -m "changes"

# ✅ BIEN
git commit -m "feat(compute): aumenta disk size a 30GB"
```

### Tareas Comunes

| Tarea | Archivos | Comando |
|-------|----------|---------|
| Cambiar machine type | variables.tf | `terraform apply` |
| Agregar firewall rule | main.tf | `terraform apply` |
| Modificar startup script | install-wordpress.sh | Recrear instancia |
| Ver IP actual | - | `terraform output` |
| Cambiar región | variables.tf + main.tf | `terraform apply` |

---

## 📌 URLs y Recursos

- **Repo WordPress:** https://github.com/camiloengineer/intranet-robotia
- **Repo Terraform:** https://github.com/camiloengineer/intranet-robotia-terraform
- **GCP Project:** intranet-robotia
- **GCP Console:** https://console.cloud.google.com/compute/instances?project=intranet-robotia
- **Terraform Docs:** https://registry.terraform.io/providers/hashicorp/google/latest/docs

---

## ✅ Validación de Infraestructura

### Checklist Post-Apply

```bash
# 1. Verificar outputs
terraform output

# 2. SSH funciona
gcloud compute ssh intranet-robotia --zone=us-central1-a

# 3. WordPress carga
curl -I http://$(terraform output -raw instance_public_ip)

# 4. Firewall permite HTTP
nmap -p 80 $(terraform output -raw instance_public_ip)

# 5. Bucket backups existe
gsutil ls gs://intranet-robotia-backups

# 6. State en GCS
gsutil ls gs://robotia-terraform-state/terraform/state/
```

---

## 🔮 Roadmap

### Corto plazo
- [ ] GitHub Actions para `terraform plan` en PRs
- [ ] Pre-commit hooks (fmt, validate)
- [ ] Checkov security scanning

### Mediano plazo
- [ ] Migrar secretos a Secret Manager
- [ ] Custom image con Packer
- [ ] Cloud Load Balancer + SSL
- [ ] Cloud SQL en lugar de MariaDB local

### Largo plazo
- [ ] Multi-region deployment
- [ ] Terraform Cloud backend
- [ ] Workspaces (dev/staging/prod)

---

## 📖 Documentación de Referencia

1. **README.md** - Quick start + usage básico
2. **TERRAFORM.md** - Arquitectura + decisiones de diseño
3. **CLAUDE.md** - Este archivo (contexto completo)
4. **main.tf** - Código fuente de recursos
5. **variables.tf** - Variables configurables
6. **outputs.tf** - Outputs disponibles

---

## ✅ Tu Rol Como Claude Code

**NUNCA hagas:**
- ❌ Commitear archivos `*.tfstate*`
- ❌ Hardcodear secretos en código
- ❌ Hacer `terraform apply` sin `plan` previo
- ❌ Destruir infraestructura sin confirmación
- ❌ Modificar backend sin backup del state

**SIEMPRE haz:**
- ✅ `terraform fmt` antes de commit
- ✅ `terraform validate` antes de commit
- ✅ `terraform plan` antes de `apply`
- ✅ Commits descriptivos (sin coautor IA)
- ✅ Documenta cambios en TERRAFORM.md

---

## 📊 Métricas del Proyecto

- **Recursos gestionados:** 5
- **Providers:** 1 (Google)
- **Variables:** 10
- **Outputs:** 10
- **Archivos .tf:** 4
- **Backend:** GCS (remoto)
- **Free tier:** 100% compliant
- **Versión Terraform:** >= 1.0

---

**Versión:** 1.0
**Última actualización:** 2025-11-08
**Creado para:** Claude Code + Futuras instancias de IA
**Mantenedor:** Camilo González (@camiloengineer.com)
