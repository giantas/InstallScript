#!/bin/bash

## fixed parameters
# IMPORTANT! Bash is case sensitive! Use true or false

OE_USER="test"
DATABASE_NAME="test_db"

#Set to true (lowercase) if you want to install it, false if you don't need it or have it already installed.
INSTALL_WKHTMLTOPDF=false

#The default port where this Odoo instance will run under (provided you use the command -c in the terminal)
#Set the default Odoo port (you still have to use -c /etc/odoo-server.conf for example to use this.)
OE_PORT="8069"

# Install Python dependencies, confirm supported versions first
# Install python2/pip2 packages
INSTALL_PIP2_DEPS=true

# Install python3/pip3 packages
INSTALL_PIP3_DEPS=true

# Set this to true (lowercase) if you want to install Odoo 11 Enterprise!
IS_ENTERPRISE=false

#set the superadmin password
OE_SUPERADMIN="admin"

# Demo data in database
WITH_DEMO_DATA=false

# Update server before installation
UPDATE_SERVER=false
