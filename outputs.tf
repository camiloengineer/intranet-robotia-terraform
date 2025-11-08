# ==============================================================================
# Robotia Intranet - Terraform Outputs
# ==============================================================================
# Outputs útiles después del terraform apply
# ==============================================================================

output "instance_name" {
  description = "Nombre de la instancia Compute Engine"
  value       = google_compute_instance.wordpress.name
}

output "instance_zone" {
  description = "Zona de la instancia"
  value       = google_compute_instance.wordpress.zone
}

output "instance_machine_type" {
  description = "Tipo de máquina"
  value       = google_compute_instance.wordpress.machine_type
}

output "instance_public_ip" {
  description = "IP pública de la instancia"
  value       = google_compute_instance.wordpress.network_interface[0].access_config[0].nat_ip
}

output "wordpress_url" {
  description = "URL del sitio WordPress"
  value       = "http://${google_compute_instance.wordpress.network_interface[0].access_config[0].nat_ip}"
}

output "wordpress_admin_url" {
  description = "URL del admin de WordPress"
  value       = "http://${google_compute_instance.wordpress.network_interface[0].access_config[0].nat_ip}/wp-admin"
}

output "backup_bucket_name" {
  description = "Nombre del bucket de backups"
  value       = google_storage_bucket.backups.name
}

output "backup_bucket_url" {
  description = "URL del bucket de backups"
  value       = google_storage_bucket.backups.url
}

output "ssh_command" {
  description = "Comando para conectar vía SSH"
  value       = "gcloud compute ssh ${google_compute_instance.wordpress.name} --zone=${google_compute_instance.wordpress.zone}"
}

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}
