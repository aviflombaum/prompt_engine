---
title: "Installation"
layout: "docs"
nav_order: "3"
---

# PromptEngine Installation Guide

This document provides a detailed installation guide for PromptEngine. Follow the steps outlined below to install and configure PromptEngine on your system.

## System Requirements

Before installing PromptEngine, ensure your system meets the following requirements:

- Operating System: Ubuntu 20.04, CentOS 8, or similar Linux distribution
- Processor: Intel i5 or higher
- RAM: 8 GB minimum
- Storage: 20 GB of free disk space
- Network: Active internet connection for installation
- Database: MySQL 5.7 or PostgreSQL 10.0

## Step-by-Step Installation

### 1. Update Your System

Make sure your system is up-to-date:

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Install Dependencies

Install required packages:

```bash
sudo apt install git curl wget -y
```

### 3. Download PromptEngine

Clone the PromptEngine repository:

```bash
git clone https://github.com/your-repository/promptengine.git
cd promptengine
```

### 4. Run Installation Script

Execute the installation script:

```bash
chmod +x install.sh
./install.sh
```

## Database Setup

### PostgreSQL Setup

1. **Install PostgreSQL:**

   ```bash
   sudo apt install postgresql postgresql-contrib -y
   ```

2. **Create a Database and User:**

   ```bash
   sudo -u postgres psql
   CREATE DATABASE promptengine;
   CREATE USER promptuser WITH ENCRYPTED PASSWORD 'yourpassword';
   GRANT ALL PRIVILEGES ON DATABASE promptengine TO promptuser;
   \q
   ```

3. **Configure PostgreSQL to Allow Local Connections:**

   Edit the `pg_hba.conf` file:

   ```bash
   sudo nano /etc/postgresql/12/main/pg_hba.conf
   ```

   Add or ensure the following line is under the "Local connections" section:

   ```
   local   all             all                                     md5
   ```

   Restart PostgreSQL:

   ```bash
   sudo systemctl restart postgresql
   ```

### MySQL Setup

1. **Install MySQL:**

   ```bash
   sudo apt install mysql-server -y
   ```

2. **Secure Installation:**

   ```bash
   sudo mysql_secure_installation
   ```

3. **Create a Database and User:**

   ```bash
   sudo mysql
   CREATE DATABASE promptengine;
   CREATE USER 'promptuser'@'localhost' IDENTIFIED BY 'yourpassword';
   GRANT ALL PRIVILEGES ON promptengine.* TO 'promptuser'@'localhost';
   FLUSH PRIVILEGES;
   EXIT;
   ```

## Configuration Options

Edit the `config.json` file in the PromptEngine directory:

```json
{
  "database_type": "PostgreSQL",  // Or "MySQL"
  "database_host": "localhost",
  "database_port": 5432,          // Use 3306 for MySQL
  "database_user": "promptuser",
  "database_password": "yourpassword",
  "database_name": "promptengine"
}
```

## Troubleshooting Common Issues

1. **Installation Script Fails:**

   - Ensure all dependencies are installed.
   - Check for errors in the console output and address them accordingly.

2. **Database Connection Issues:**

   - Verify that the database service is running.
   - Check that your database credentials in `config.json` are correct.
   - Ensure that the database server allows connections from your PromptEngine application.

3. **Performance Issues:**

   - Check system resources (CPU, RAM, and disk space).
   - Consider increasing the system specifications if performance is consistently poor.

For more detailed troubleshooting, consult the system logs or contact support.
