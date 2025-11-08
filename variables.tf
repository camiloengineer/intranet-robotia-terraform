# ==============================================================================
# Robotia Intranet - Terraform Variables
# ==============================================================================
# Variables configurables para la infraestructura GCP
# ==============================================================================

variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "intranet-robotia"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "GCP Compute Engine machine type"
  type        = string
  default     = "e2-micro"
}

variable "instance_name" {
  description = "Nombre de la instancia Compute Engine"
  type        = string
  default     = "intranet-robotia"
}

variable "boot_disk_size" {
  description = "Tamaño del disco boot en GB"
  type        = number
  default     = 20
}

variable "boot_disk_type" {
  description = "Tipo de disco boot"
  type        = string
  default     = "pd-standard"
}

variable "image_family" {
  description = "Familia de imagen del SO"
  type        = string
  default     = "debian-12"
}

variable "image_project" {
  description = "Proyecto de la imagen del SO"
  type        = string
  default     = "debian-cloud"
}

variable "network_tags" {
  description = "Network tags para la instancia"
  type        = list(string)
  default     = ["http-server", "https-server"]
}
