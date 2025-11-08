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
├── backend.tf              # Configuración backend GCS
├── main.tf                 # Recursos principales (Compute, Firewall, Storage)
├── variables.tf            # Variables configurables
├── outputs.tf              # Outputs útiles (IP, URLs, comandos)
├── install-wordpress.sh    # Script de instalación WordPress (metadata_startup_script)
├── .gitignore              # Exclusiones (state, tfvars, etc.)
├── README.md               # Este archivo
└── TERRAFORM.md            # Documentación arquitectura
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

## 🔄 Workflow Típico

### Escenario 1: Recrear servidor desde cero

```bash
git clone git@github.com:camiloengineer/intranet-robotia-terraform.git
cd intranet-robotia-terraform
terraform init
terraform apply
# Esperar ~5 minutos (instalación WordPress)
# Conectar vía SSH y restaurar backup
```

### Escenario 2: Cambiar tipo de máquina

```bash
# Editar variables.tf o crear terraform.tfvars
echo 'machine_type = "e2-small"' > terraform.tfvars

terraform plan   # Ver cambios
terraform apply  # Aplicar (requiere recrear instancia)
```

### Escenario 3: Agregar nuevo firewall

```bash
# Editar main.tf
# Agregar nuevo recurso google_compute_firewall

terraform plan
terraform apply
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
