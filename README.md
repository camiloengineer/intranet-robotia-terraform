# Robotia Intranet - Terraform Infrastructure as Code

> Infraestructura completa de la Intranet Robotia definida con Terraform para Google Cloud Platform

## 📋 Descripción

Este repositorio contiene la definición IaC (Infrastructure as Code) completa para recrear la infraestructura de producción de la Intranet Robotia en GCP.

## 🏗️ Recursos Gestionados

| Recurso | Tipo | Descripción |
|---------|------|-------------|
| `google_compute_instance.wordpress` | Compute Engine | Instancia e2-micro con Debian 12 + LAMP + WordPress |
| `google_compute_firewall.allow_http` | Firewall | Permite tráfico HTTP (puerto 80) |
| `google_compute_firewall.allow_https` | Firewall | Permite tráfico HTTPS (puerto 443) |
| `google_storage_bucket.backups` | Cloud Storage | Bucket para backups con lifecycle 90 días |
| `google_storage_bucket.terraform_state` | Cloud Storage | Bucket para Terraform state (con versionado) |

## 🚀 Quick Start

### Opción 1: CI/CD con GitHub Actions (Recomendado)

El repositorio incluye workflows automatizados:

- **Pull Requests → `terraform plan`** - Revisa cambios antes de merge
- **Push a `main` → `terraform apply`** - Despliega automáticamente

**Setup inicial:**

```bash
# 1. Crear Service Account en GCP
gcloud iam service-accounts create terraform-github-actions \
  --display-name="Terraform GitHub Actions"

# 2. Asignar permisos necesarios
gcloud projects add-iam-policy-binding intranet-robotia \
  --member="serviceAccount:terraform-github-actions@intranet-robotia.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

gcloud projects add-iam-policy-binding intranet-robotia \
  --member="serviceAccount:terraform-github-actions@intranet-robotia.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding intranet-robotia \
  --member="serviceAccount:terraform-github-actions@intranet-robotia.iam.gserviceaccount.com" \
  --role="roles/compute.networkAdmin"

# 3. Crear y descargar key JSON
gcloud iam service-accounts keys create terraform-sa-key.json \
  --iam-account=terraform-github-actions@intranet-robotia.iam.gserviceaccount.com

# 4. Configurar GitHub Secrets (Settings → Secrets and variables → Actions)
# - GCP_PROJECT_ID: intranet-robotia
# - GCP_SA_KEY: <contenido de terraform-sa-key.json>

# 5. Hacer push y dejar que GitHub Actions maneje todo
git add .
git commit -m "feat: enable CI/CD for Terraform"
git push origin main
```

**Workflow:**

```bash
# Crear feature branch
git checkout -b feature/upgrade-machine-type

# Editar archivos .tf
vim main.tf

# Crear Pull Request
git push origin feature/upgrade-machine-type
# → GitHub Actions ejecuta `terraform plan` y comenta en el PR

# Hacer merge a main
# → GitHub Actions ejecuta `terraform apply` automáticamente
```

### Opción 2: Uso Local (Manual)

### Pre-requisitos

```bash
# Instalar Terraform
wget https://releases.hashicorp.com/terraform/1.10.4/terraform_1.10.4_linux_amd64.zip
unzip terraform_1.10.4_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verificar instalación
terraform --version

# Autenticarse en GCP
gcloud auth application-default login
gcloud config set project intranet-robotia
```

### Uso

```bash
# 1. Clonar repositorio
git clone git@github.com:camiloengineer/intranet-robotia-terraform.git
cd intranet-robotia-terraform

# 2. Inicializar Terraform (descarga providers, configura backend)
terraform init

# 3. Ver plan de ejecución (qué se va a crear/modificar)
terraform plan

# 4. Aplicar cambios (crear infraestructura)
terraform apply

# 5. Ver outputs (IP pública, URLs, comandos SSH)
terraform output
```

## 📂 Estructura del Proyecto

```
intranet-robotia-terraform/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml   # CI: plan en PRs
│       └── terraform-apply.yml  # CD: apply en push a main
├── backend.tf                   # Configuración backend GCS
├── main.tf                      # Recursos principales (Compute, Firewall, Storage)
├── variables.tf                 # Variables configurables
├── outputs.tf                   # Outputs útiles (IP, URLs, comandos)
├── install-wordpress.sh         # Script de instalación WordPress (metadata_startup_script)
├── .gitignore                   # Exclusiones (state, tfvars, etc.)
├── README.md                    # Este archivo
└── TERRAFORM.md                 # Documentación arquitectura
```

## ⚙️ Variables Configurables

| Variable | Default | Descripción |
|----------|---------|-------------|
| `project_id` | `intranet-robotia` | GCP Project ID |
| `region` | `us-central1` | GCP Region |
| `zone` | `us-central1-a` | GCP Zone |
| `machine_type` | `e2-micro` | Tipo de máquina (free tier) |
| `instance_name` | `intranet-robotia` | Nombre de la instancia |
| `boot_disk_size` | `20` | Tamaño disco en GB |

**Personalizar variables:**

```bash
# Crear terraform.tfvars (no se commitea)
cat > terraform.tfvars <<EOF
machine_type = "e2-small"
boot_disk_size = 30
EOF

terraform apply
```

## 📊 Outputs Disponibles

Después de `terraform apply`, obtienes:

```bash
terraform output

# Outputs:
instance_name        = "intranet-robotia"
instance_public_ip   = "34.10.120.91"
wordpress_url        = "http://34.10.120.91"
wordpress_admin_url  = "http://34.10.120.91/wp-admin"
ssh_command          = "gcloud compute ssh intranet-robotia --zone=us-central1-a"
backup_bucket_name   = "intranet-robotia-backups"
```

## 🔐 Backend Remoto (GCS)

El Terraform state se guarda en Google Cloud Storage, **NO localmente**.

```hcl
# backend.tf
terraform {
  backend "gcs" {
    bucket = "robotia-terraform-state"
    prefix = "terraform/state"
  }
}
```

**Beneficios:**
- ✅ State compartido entre desarrolladores
- ✅ Versionado automático
- ✅ Locking para evitar conflictos
- ✅ Encriptación en reposo

## 🧹 Destruir Infraestructura

```bash
# Ver qué se va a destruir
terraform plan -destroy

# Destruir TODO (¡CUIDADO!)
terraform destroy

# Destruir solo un recurso específico
terraform destroy -target=google_compute_instance.wordpress
```

## 🚀 Cómo Levantar y Ejecutar el Proyecto

### Método 1: CI/CD Automático (Recomendado - Sin Terraform Local)

**Primera vez - Setup de GitHub Actions:**

```bash
# 1. Crear Service Account para GitHub Actions
gcloud iam service-accounts create terraform-github-actions \
  --display-name="Terraform GitHub Actions" \
  --project=intranet-robotia

# 2. Asignar permisos necesarios
for role in roles/compute.admin roles/storage.admin roles/compute.networkAdmin; do
  gcloud projects add-iam-policy-binding intranet-robotia \
    --member="serviceAccount:terraform-github-actions@intranet-robotia.iam.gserviceaccount.com" \
    --role="$role"
done

# 3. Crear y descargar key JSON
gcloud iam service-accounts keys create ~/terraform-sa-key.json \
  --iam-account=terraform-github-actions@intranet-robotia.iam.gserviceaccount.com

# 4. Copiar contenido del archivo para GitHub Secrets
cat ~/terraform-sa-key.json

# 5. Ir a GitHub: Settings → Secrets and variables → Actions → New repository secret
#    - Name: GCP_SA_KEY
#    - Value: <pegar contenido del JSON>
#
#    - Name: GCP_PROJECT_ID
#    - Value: intranet-robotia

# 6. Limpiar archivo local (seguridad)
rm ~/terraform-sa-key.json
```

**Uso diario:**

```bash
# 1. Clonar repositorio
git clone git@github.com:camiloengineer/intranet-robotia-terraform.git
cd intranet-robotia-terraform

# 2. Crear feature branch
git checkout -b feature/mi-cambio

# 3. Editar archivos .tf según necesites
vim main.tf

# 4. Commit y push
git add .
git commit -m "feat: descripción del cambio"
git push origin feature/mi-cambio

# 5. Crear Pull Request en GitHub
#    → GitHub Actions ejecutará 'terraform plan' automáticamente
#    → Verás el plan comentado en el PR

# 6. Hacer merge del PR a main
#    → GitHub Actions ejecutará 'terraform apply' automáticamente
#    → Infraestructura se actualiza sin intervención manual

# 7. Verificar deployment
#    → Ver logs en Actions tab de GitHub
#    → Verificar outputs en los logs del workflow
```

### Método 2: Ejecución Local (Manual)

**Primera vez - Setup local:**

```bash
# 1. Instalar Terraform
wget https://releases.hashicorp.com/terraform/1.10.4/terraform_1.10.4_linux_amd64.zip
unzip terraform_1.10.4_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version

# 2. Autenticarse en GCP
gcloud auth application-default login
gcloud config set project intranet-robotia

# 3. Verificar que el bucket de backend existe
gsutil ls gs://robotia-terraform-state || \
  gsutil mb -p intranet-robotia -c STANDARD -l us-central1 gs://robotia-terraform-state

# 4. Habilitar versionado del bucket
gsutil versioning set on gs://robotia-terraform-state

# 5. Clonar repositorio
git clone git@github.com:camiloengineer/intranet-robotia-terraform.git
cd intranet-robotia-terraform

# 6. Inicializar Terraform (descargar providers y configurar backend)
terraform init
```

**Uso diario:**

```bash
# 1. Actualizar código
git pull origin main

# 2. Editar archivos según necesites
vim main.tf

# 3. Formatear código
terraform fmt

# 4. Validar sintaxis
terraform validate

# 5. Ver plan de cambios (QUÉ se va a crear/modificar/destruir)
terraform plan

# 6. Aplicar cambios (EJECUTAR las modificaciones)
terraform apply
# Revisar el plan que muestra
# Escribir 'yes' para confirmar

# 7. Ver outputs (IP, URLs, comandos útiles)
terraform output

# 8. Commit y push cambios
git add .
git commit -m "feat: descripción del cambio"
git push origin main
```

## 🔄 Workflow Típico

### Escenario 1: Recrear servidor desde cero

**Con CI/CD:**
```bash
git clone git@github.com:camiloengineer/intranet-robotia-terraform.git
cd intranet-robotia-terraform
# Hacer push a main → GitHub Actions aplica automáticamente
# Esperar ~5-10 minutos
# Verificar en Actions tab de GitHub
```

**Local:**
```bash
git clone git@github.com:camiloengineer/intranet-robotia-terraform.git
cd intranet-robotia-terraform
terraform init
terraform apply
# Esperar ~5 minutos (instalación WordPress)
# Conectar vía SSH y restaurar backup si es necesario
```

### Escenario 2: Cambiar tipo de máquina

**Con CI/CD:**
```bash
git checkout -b feature/upgrade-machine
echo 'machine_type = "e2-small"' > terraform.tfvars
git add terraform.tfvars
git commit -m "feat: upgrade machine type to e2-small"
git push origin feature/upgrade-machine
# Crear PR → revisar plan → merge → apply automático
```

**Local:**
```bash
echo 'machine_type = "e2-small"' > terraform.tfvars
terraform plan   # Ver cambios
terraform apply  # Aplicar (requiere recrear instancia)
git add terraform.tfvars
git commit -m "feat: upgrade machine type to e2-small"
git push origin main
```

### Escenario 3: Agregar nuevo firewall

**Con CI/CD:**
```bash
git checkout -b feature/add-ssh-firewall
vim main.tf  # Agregar recurso google_compute_firewall
git add main.tf
git commit -m "feat: add SSH firewall rule"
git push origin feature/add-ssh-firewall
# Crear PR → revisar plan → merge → apply automático
```

**Local:**
```bash
vim main.tf  # Agregar nuevo recurso google_compute_firewall
terraform plan
terraform apply
git add main.tf
git commit -m "feat: add SSH firewall rule"
git push origin main
```

## 🐛 Troubleshooting

### Error: Backend bucket no existe

```bash
# Crear bucket manualmente primero
gsutil mb -p intranet-robotia -c STANDARD -l us-central1 gs://robotia-terraform-state
gsutil versioning set on gs://robotia-terraform-state
```

### Error: Permisos insuficientes

```bash
# Verificar permisos de la cuenta
gcloud auth application-default login
gcloud projects get-iam-policy intranet-robotia

# Necesitas al menos:
# - roles/compute.admin
# - roles/storage.admin
# - roles/compute.networkAdmin
```

### Instancia creada pero WordPress no carga

```bash
# Ver logs del startup script
gcloud compute ssh intranet-robotia --zone=us-central1-a
sudo journalctl -u google-startup-scripts.service
```

## 📖 Documentación Adicional

- **TERRAFORM.md** - Arquitectura detallada y decisiones de diseño
- **[main.tf](./main.tf)** - Código fuente de recursos
- **[install-wordpress.sh](./install-wordpress.sh)** - Script de instalación

## 🔗 Recursos Relacionados

- **Repo WordPress:** https://github.com/camiloengineer/intranet-robotia
- **GCP Project:** `intranet-robotia`
- **Terraform Docs:** https://registry.terraform.io/providers/hashicorp/google/latest/docs

## 👤 Mantenedor

**Camilo González** (camilo@camiloengineer.com)

## 📄 Licencia

Uso interno - Robotia

---

**Versión:** 1.0
**Última actualización:** 2025-11-08
**Terraform:** >= 1.0
**Provider Google:** ~> 6.0
