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

# Install nginx web server, PHP, and MySQL
read -p "Do you want to install nginx web server, PHP, PHP fpm, and PHP mysql (y/N)? " response
if [[ $response == "y" || $response == "Y" ]]; then
    sudo apt install nginx php php-fpm php-mysql
else
    echo "Skipping nginx, PHP, and MySQL installation."
fi

# Install Let's Encrypt
sudo apt install certbot -y

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

sudo touch /etc/nginx/sites-available/"$domain_name".conf
cat << EOF > /etc/nginx/sites-available/"$domain_name".conf
server {
    listen 80;
    server_name $domain_name www.$domain_name;

    root /var/www/html/wordpress;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Enable the virtual host configuration
sudo a2ensite "$domain_name".conf

# Create a symbolic link for the virtual host configuration
sudo ln -s /etc/nginx/sites-available/"$domain_name".conf /etc/nginx/sites-enabled/"$domain_name".conf

# Reload Nginx configuration
sudo systemctl reload nginx

# Configure Let's Encrypt SSL and automatic renewal
sudo certbot certonly --agree-tos --non-interactive --email="$admin_email" --redirect --renew-before-expiry --post-hook "systemctl reload nginx" --agree-tos --email="$admin_email" --domain "$website_url"
