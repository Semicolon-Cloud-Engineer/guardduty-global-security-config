#!/bin/bash

# Define the new password
NEW_PASSWORD="passwordreset"

# Stop the MySQL service
echo "Stopping MySQL service..."
sudo service mysql stop

# Ensure the directory exists
echo "Ensuring /var/run/mysqld exists..."
sudo mkdir -p /var/run/mysqld
sudo chown mysql:mysql /var/run/mysqld

# Start MySQL in safe mode
echo "Starting MySQL in safe mode..."
sudo mysqld_safe --skip-grant-tables &
sleep 30  # Wait longer to ensure MySQL starts

# Change the MySQL root password
echo "Changing MySQL root password..."
mysql -u root <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEW_PASSWORD}';
EOF

# Kill the MySQL safe mode process
echo "Killing MySQL safe mode..."
sudo pkill mysqld
sudo pkill mysqld_safe

# Restart the MySQL service
echo "Restarting MySQL service..."
sudo service mysql start

echo "Password reset completed successfully!"
