# ==============================================================================
# Robotia Intranet - Terraform Backend Configuration
# ==============================================================================
# Backend remoto en Google Cloud Storage para state management
#
# IMPORTANTE:
# - Ejecutar PRIMERO: terraform init -backend-config=backend.hcl
# - El bucket 'robotia-terraform-state' debe existir previamente
# ==============================================================================

terraform {
  backend "gcs" {
    bucket = "robotia-terraform-state"
    prefix = "terraform/state"
  }

  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
