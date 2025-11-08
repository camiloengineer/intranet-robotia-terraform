# Robotia Intranet - Arquitectura Terraform

> Documentación técnica de decisiones de diseño y arquitectura IaC

## 📐 Decisiones de Diseño

### 1. Backend Remoto en GCS

**Decisión:** Usar Google Cloud Storage en lugar de backend local

**Razones:**
- ✅ State compartido entre múltiples desarrolladores
- ✅ Versionado automático (recuperación ante errores)
- ✅ State locking (evita conflictos concurrentes)
- ✅ Encriptación en reposo por defecto
- ✅ No requiere infraestructura adicional (Terraform Cloud, Consul, etc.)

**Implementación:**
```hcl
terraform {
  backend "gcs" {
    bucket = "robotia-terraform-state"
    prefix = "terraform/state"
  }
}
```

**Bucket configurado con:**
- Versioning habilitado
- Uniform bucket-level access
- No lifecycle (mantener history completo)

### 2. Módulos vs. Flat Structure

**Decisión:** Estructura plana (sin módulos)

**Razones:**
- ✅ Proyecto pequeño (5 recursos)
- ✅ No hay reutilización de código
- ✅ Más simple de entender para nuevos devs
- ✅ KISS principle

**Si crece el proyecto, migrar a:**
```
modules/
├── compute/
├── networking/
└── storage/
```

### 3. Metadata Startup Script

**Decisión:** Usar `metadata_startup_script` en lugar de imágenes custom

**Razones:**
- ✅ Más flexible (editar script sin recrear imagen)
- ✅ Código visible en Terraform
- ✅ No requiere pipeline de build de imágenes
- ✅ WordPress siempre a la última versión

**Trade-offs:**
- ⚠️ Tiempo de arranque ~5-7 minutos (vs ~1 min con imagen custom)
- ⚠️ Red pública requerida para descargar paquetes

**Mejora futura:** Migrar a imagen custom con Packer

### 4. Firewall Rules

**Decisión:** Firewall rules separados en lugar de uno solo

**Razones:**
- ✅ Más granular (deshabilitar HTTP sin afectar HTTPS)
- ✅ Mejor documentación (descripción por regla)
- ✅ Fácil agregar SSH selectivo en el futuro

```hcl
resource "google_compute_firewall" "allow_http" { ... }
resource "google_compute_firewall" "allow_https" { ... }
```

### 5. Variables con Defaults

**Decisión:** Todas las variables tienen valores por defecto

**Razones:**
- ✅ `terraform apply` funciona sin argumentos
- ✅ Reproducibilidad (mismo resultado sin tfvars)
- ✅ Documentación inline de valores típicos

**Override con:**
```bash
terraform apply -var="machine_type=e2-small"
# O crear terraform.tfvars
```

### 6. Labels Consistentes

**Decisión:** Labels en todos los recursos

```hcl
labels = {
  environment = "production"
  app         = "robotia-intranet"
  managed-by  = "terraform"
}
```

**Beneficios:**
- ✅ Facturación detallada por app
- ✅ Filtrado en GCP Console
- ✅ Auditoría de recursos managed

### 7. Lifecycle Policies

**Decisión:** Lifecycle solo en backups bucket (90 días)

**Razones:**
- ✅ Ahorro de costos (borrar backups antiguos)
- ✅ Cumplimiento con política de retención
- ✅ State bucket SIN lifecycle (mantener history completo)

```hcl
lifecycle_rule {
  condition { age = 90 }
  action { type = "Delete" }
}
```

### 8. Free Tier Compliance

**Decisión:** Todos los recursos dentro del free tier

| Recurso | Free Tier | Config |
|---------|-----------|--------|
| Compute Engine | 1x e2-micro (us-central1) | ✅ |
| Storage | 5GB/mes | ✅ (backups < 5GB) |
| Network Egress | 1GB/mes | ✅ |

**Si se excede free tier, cambiar a:**
- Preemptible instance (80% descuento)
- Nearline storage para backups (50% más barato)

## 🔄 State Management

### Estructura del State

```json
{
  "version": 4,
  "terraform_version": "1.10.4",
  "resources": [
    {
      "type": "google_compute_instance",
      "name": "wordpress",
      "provider": "provider[\"hashicorp/google\"]",
      ...
    }
  ]
}
```

### State Locking

GCS hace locking automático usando:
- Object versioning
- Generation numbers
- Conditional writes

**Verificar lock:**
```bash
gsutil ls -L gs://robotia-terraform-state/terraform/state/default.tflock
```

### Recuperación de State

```bash
# Listar versiones
gsutil ls -a gs://robotia-terraform-state/terraform/state/

# Restaurar versión anterior
gsutil cp gs://robotia-terraform-state/terraform/state/default.tfstate#1234567890 \
  gs://robotia-terraform-state/terraform/state/default.tfstate
```

## 🔐 Seguridad

### Secretos NO en Terraform

**❌ NO hacer:**
```hcl
variable "db_password" {
  default = "wppass123"  # ¡MAL! Visible en state
}
```

**✅ Usar GCP Secret Manager:**
```bash
# En producción, leer secretos con:
gcloud secrets versions access latest --secret="DB_PASSWORD"
```

### IAM Mínimo

Service accounts con permisos justos:
```yaml
- roles/compute.instanceAdmin.v1  # Crear/modificar instancias
- roles/compute.securityAdmin     # Firewall rules
- roles/storage.admin             # Buckets
```

**NO usar:** `roles/owner` ni `roles/editor`

## 📊 Outputs Strategy

### Outputs Útiles

```hcl
output "ssh_command" {
  description = "Comando listo para copiar/pegar"
  value = "gcloud compute ssh ${...}"
}
```

**Mejora futura:** Sensitive outputs para credenciales

```hcl
output "db_password" {
  value     = data.google_secret_manager_secret_version.db_password.secret_data
  sensitive = true
}
```

## 🚀 Deployment Strategy

### Opción 1: CI/CD con GitHub Actions (Recomendado)

**Flujo automatizado:**

1. **Pull Requests** → `terraform plan`
   - Workflow: `.github/workflows/terraform-plan.yml`
   - Ejecuta: `fmt`, `validate`, `plan`
   - Comenta el plan en el PR automáticamente

2. **Push a `main`** → `terraform apply`
   - Workflow: `.github/workflows/terraform-apply.yml`
   - Ejecuta: `fmt`, `validate`, `plan`, `apply`
   - Health check automático
   - Outputs visibles en logs

**Triggers:**
```yaml
on:
  pull_request:
    paths:
      - '**.tf'
      - 'install-wordpress.sh'
  push:
    branches: [main]
    paths:
      - '**.tf'
```

**Secretos necesarios:**
- `GCP_PROJECT_ID`: intranet-robotia
- `GCP_SA_KEY`: JSON key de Service Account con permisos:
  - `roles/compute.admin`
  - `roles/storage.admin`
  - `roles/compute.networkAdmin`

**Ventajas:**
- ✅ No requiere Terraform local
- ✅ Plan automático en cada PR
- ✅ Historial de cambios en Actions
- ✅ Rollback con `git revert`

### Opción 2: Plan → Apply Manual (Local)

```bash
# 1. Hacer cambios en .tf
vim main.tf

# 2. Ver diff
terraform plan -out=tfplan

# 3. Revisar plan
terraform show tfplan

# 4. Aplicar
terraform apply tfplan
```

### Cambios Destructivos

Terraform avisa si va a destruir/recrear:
```
~ google_compute_instance.wordpress must be replaced
  - machine_type = "e2-micro" -> "e2-small" # forces replacement
```

**Protección:**
```hcl
lifecycle {
  prevent_destroy = true  # Requiere -target para destruir
}
```

## 🧪 Testing Strategy

### 1. Terraform Validate

```bash
terraform validate
# Success! The configuration is valid.
```

### 2. Terraform Plan (CI/CD)

```yaml
# GitHub Actions
- run: terraform plan -no-color
  continue-on-error: false
```

### 3. Checkov (Security Scanning)

```bash
pip install checkov
checkov -d .
# Escanea por vulnerabilidades (public buckets, weak crypto, etc.)
```

### 4. TFLint (Linting)

```bash
tflint
# Detecta deprecated sintaxis, unused variables
```

## 📈 Escalabilidad Futura

### Migrar a Módulos

Cuando haya >10 recursos:

```
modules/
├── compute/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── networking/
└── storage/

main.tf:
module "compute" {
  source = "./modules/compute"
  ...
}
```

### Multi-Environment

```
environments/
├── dev/
│   └── terraform.tfvars
├── staging/
│   └── terraform.tfvars
└── production/
    └── terraform.tfvars
```

```bash
terraform workspace new dev
terraform workspace select dev
terraform apply -var-file=environments/dev/terraform.tfvars
```

### Terragrunt (DRY)

Para evitar duplicación entre envs:

```hcl
# terragrunt.hcl
terraform {
  source = "../../modules/wordpress"
}

inputs = {
  environment = "production"
}
```

## 🎯 Best Practices Aplicadas

✅ State remoto con versionado
✅ Variables con defaults sensatos
✅ Outputs útiles (comandos copy-paste)
✅ Labels consistentes
✅ Free tier compliance
✅ .gitignore completo
✅ Documentación inline (comments)
✅ Firewall granular
✅ Lifecycle policies en backups
✅ No hardcodear secretos

## 🔮 Roadmap

### Corto plazo
- [x] GitHub Actions para `terraform plan` en PRs
- [x] GitHub Actions para `terraform apply` en push a main
- [ ] Pre-commit hooks (terraform fmt, validate)
- [ ] Checkov en CI/CD

### Mediano plazo
- [ ] Migrar secretos a Secret Manager
- [ ] Custom image con Packer (reducir boot time)
- [ ] Cloud Load Balancer + SSL cert
- [ ] Cloud SQL en lugar de MariaDB local

### Largo plazo
- [ ] Multi-region deployment
- [ ] Terraform Cloud backend
- [ ] Módulos reutilizables
- [ ] Workspaces (dev/staging/prod)

---

**Versión:** 1.0
**Última actualización:** 2025-11-08
**Autor:** Camilo González
