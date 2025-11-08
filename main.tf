# ==============================================================================
# Robotia Intranet - Terraform Main Configuration
# ==============================================================================
# Infraestructura completa en GCP:
# - Compute Engine (e2-micro)
# - Firewall rules (HTTP/HTTPS)
# - Storage bucket (backups)
# ==============================================================================

# ------------------------------------------------------------------------------
# Compute Engine Instance
# ------------------------------------------------------------------------------
resource "google_compute_instance" "wordpress" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = var.network_tags

  boot_disk {
    initialize_params {
      image = "${var.image_project}/${var.image_family}"
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = file("${path.module}/install-wordpress.sh")

  metadata = {
    enable-oslogin = "TRUE"
  }

  labels = {
    environment = "production"
    app         = "robotia-intranet"
    managed-by  = "terraform"
  }

  scheduling {
    automatic_restart = true
    preemptible       = false
  }

  lifecycle {
    ignore_changes = [
      metadata_startup_script,
    ]
  }
}

# ------------------------------------------------------------------------------
# Firewall Rule: Allow HTTP (80)
# ------------------------------------------------------------------------------
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-robotia-intranet"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]

  description = "Allow HTTP traffic to Robotia Intranet"
}

# ------------------------------------------------------------------------------
# Firewall Rule: Allow HTTPS (443)
# ------------------------------------------------------------------------------
resource "google_compute_firewall" "allow_https" {
  name    = "allow-https-robotia-intranet"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]

  description = "Allow HTTPS traffic to Robotia Intranet"
}

# ------------------------------------------------------------------------------
# Storage Bucket: Backups
# ------------------------------------------------------------------------------
resource "google_storage_bucket" "backups" {
  name          = "intranet-robotia-backups"
  location      = var.region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = "production"
    app         = "robotia-intranet"
    managed-by  = "terraform"
  }
}

# ------------------------------------------------------------------------------
# Storage Bucket: Terraform State
# ------------------------------------------------------------------------------
resource "google_storage_bucket" "terraform_state" {
  name          = "robotia-terraform-state"
  location      = var.region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  labels = {
    environment = "production"
    app         = "robotia-intranet"
    managed-by  = "terraform"
    purpose     = "terraform-state"
  }
}
