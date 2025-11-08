#!/bin/bash
# ==============================================================================
# Robotia Intranet - Script de Instalación WordPress en GCP
# ==============================================================================
# Instalación completa de LAMP + WordPress en Debian 12
# Este script se ejecuta automáticamente al crear la instancia (metadata_startup_script)
# ==============================================================================

set -e

echo "========================================="
echo "Robotia Intranet - Instalación WordPress"
echo "========================================="

# Actualizar sistema
apt-get update
apt-get upgrade -y

# Instalar Apache
apt-get install -y apache2
systemctl enable apache2
systemctl start apache2

# Instalar MariaDB
apt-get install -y mariadb-server
systemctl enable mariadb
systemctl start mariadb

# Instalar PHP 8.x
apt-get install -y php php-mysql libapache2-mod-php php-cli php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip

# Descargar WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
rm -rf /var/www/html/*
cp -r wordpress/* /var/www/html/

# Permisos WordPress
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

# Configurar MariaDB (NOTA: Usar secretos de GCP Secret Manager en producción)
mysql -e "CREATE DATABASE IF NOT EXISTS wordpress;"
mysql -e "CREATE USER IF NOT EXISTS 'wpuser'@'localhost' IDENTIFIED BY 'wppass123';"
mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Configurar wp-config.php
cd /var/www/html
cp wp-config-sample.php wp-config.php
sed -i "s/database_name_here/wordpress/" wp-config.php
sed -i "s/username_here/wpuser/" wp-config.php
sed -i "s/password_here/wppass123/" wp-config.php
sed -i "s/localhost/localhost/" wp-config.php

# Generar salts únicos
SALTS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
STRING='put your unique phrase here'
printf '%s\n' "g/$STRING/d" a "$SALTS" . w | ed -s wp-config.php

# Reiniciar Apache
systemctl restart apache2

echo "========================================="
echo "✅ WordPress instalado correctamente"
echo "========================================="
