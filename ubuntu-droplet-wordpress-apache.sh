#!/bin/bash

# Add the WordPress PPA for Ubuntu
read -p "Do you want to add the WordPress PPA for Ubuntu (y/N)? " response
if [[ $response == "y" || $response == "Y" ]]; then
    sudo add-apt-repository ppa:ondrej/php
else
    echo "Skipping WordPress PPA installation."
fi

# Update the package list
sudo apt update

# Install Apache web server, PHP and MySQL
read -p "Do you want to install Apache web server, PHP 7.4, PHP 7.4-fpm, and PHP 7.4-mysql (y/N)? " response
if [[ $response == "y" || $response == "Y" ]]; then
    sudo apt install apache2 php php-fpm php-mysql
else
    echo "Skipping Apache, PHP, and MySQL installation."
fi

# Install Apache2 mod_rewrite module
read -p "Do you want to install Apache2 mod_rewrite module (y/N)? " response
if [[ $response == "y" || $response == "Y" ]]; then
    sudo a2enmod rewrite
else
    echo "Skipping Apache2 mod_rewrite module installation."
fi

# Enable and start Apache2 web server
sudo systemctl enable apache2
sudo systemctl start apache2

# Install WP-CLI
read -p "Do you want to install WP-CLI (y/N)? " response
if [[ $response == "y" || $response == "Y" ]]; then
    curl -OL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
    sudo chmod +x /usr/local/bin/wp
else
    echo "Skipping WP-CLI installation."
fi  

# Create a new WordPress installation
read -p "Enter your WordPress website URL (e.g., example.com): " website_url
read -p "Enter your WordPress site title: " site_title
read -p "Enter the admin username for WordPress: " admin_user
read -p "Enter the admin password for WordPress: " admin_password
read -p "Enter the admin email for WordPress: " admin_email

sudo wp core install --quiet --url="$website_url" --title="$site_title" --admin_user="$admin_user" --admin_password="$admin_password" --admin_email="$admin_email"

# Create a virtual host configuration for WordPress
read -p "Enter your WordPress domain name (e.g., example.com): " domain_name

sudo touch /etc/apache2/sites-available/"$domain_name".conf
cat << EOF > /etc/apache2/sites-available/"$domain_name".conf
<VirtualHost *:80>
    ServerName $domain_name
    DocumentRoot /var/www/html/wordpress
    <Directory /var/www/html/wordpress>
        DirectoryIndex index.php index.html
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Enable the virtual host configuration
sudo a2ensite $domain_name.conf

# Create a symbolic link for the virtual host configuration
sudo ln -s /etc/apache2/sites-available/$domain_name.conf /etc/apache2/sites-enabled/$domain_name.conf

# Reload Apache2 configuration
sudo systemctl reload apache2

# Enable automatic daily security updates for APT
sudo apt update
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades

# Select the following options:
#   -- Automatic updates daily at 03:00 (UTC)
#   -- Download updates when possible, but don't automatically install them.
#   -- Install unattended security updates.
#   -- Do not install unattended kernel upgrades.

# Save the configuration and exit
echo "Automatic security updates enabled."
