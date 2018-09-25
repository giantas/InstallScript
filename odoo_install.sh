#!/bin/bash
################################################################################
# Script for installing Odoo on Ubuntu 14.04, 15.04 and 16.04 (could be used for other version too)
# Author: Aswa Paul
# Author: Yenthe Van Ginneken
#-------------------------------------------------------------------------------
# IMPORTANT! This script contains extra libraries that are specifically needed for Odoo 11.0
#
# This script will install Odoo on your Ubuntu OS. It can install multiple Odoo instances
# in one OS because of the different xmlrpc_ports
#-------------------------------------------------------------------------------
# Make a new file:
# sudo nano odoo-install.sh
# Place this content in it and then make the file executable:
# sudo chmod +x odoo-install.sh
# Execute the script to install Odoo:
# ./odoo-install
################################################################################

# Color codes
DARKRED='\033[0;31m'
RED='\033[1;31m'
NOCOLOR='\033[0m'
CYAN='\033[1;36m'
this_script=`basename "$0"`

# Check if branch was provided
BRANCH="$1"

if [[ "$BRANCH" == "" ]];then
    echo -e "${DARKRED}Error...${NOCOLOR}";
    echo -e "\n${RED}required: version ${NOCOLOR}(e.g 11.0, 10.0, master, etc)";
    echo -e "\ntry running: \n\t${CYAN}bash $this_script 11.0${NOCOLOR}\n"
    exit 1;

else
    # Check if branch exists
    branch_exists=`git ls-remote --heads https://github.com/odoo/odoo.git ${BRANCH} | wc -l`
    
    if [ "$branch_exists" -eq 0 ]; then
        echo -e "${RED}Branch '${BRANCH}' not found!${NOCOLOR}"
        exit 1
        
    else
        OE_VERSION=$BRANCH
        . config.sh
        
    fi
    
fi

OE_HOME="/$OE_USER"
OE_HOME_EXT="/$OE_USER/${OE_USER}-server"
OE_PREFIX="${OE_USER}-server"
OE_CONFIG="/etc/${OE_PREFIX}.conf"
OE_SERVICE="${OE_USER}.service"

function table {
    printf "%-40s | ${CYAN}%-40s${NOCOLOR}\n" "$1" "$2"
}

##Show fixed parameters
echo -e "${CYAN}Sourced parameters: ${NOCOLOR}\n"
table "User" "${OE_USER}"
table "Port" "${OE_PORT}"
table "SuperAdmin Password" "${OE_SUPERADMIN}"
table "Database" "${DATABASE_NAME}"
table "Install wkhtmltopdf" "${INSTALL_WKHTMLTOPDF}"
table "Install Python2 dependencies" "${INSTALL_PIP2_DEPS}"
table "Install Python3 dependencies" "${INSTALL_PIP3_DEPS}"
table "Branch" "${BRANCH}"
table "Install Enterprise Version" "${IS_ENTERPRISE}"
table "Demo data" "${WITH_DEMO_DATA}"

echo -e "\n${CYAN}Implied parameters: ${NOCOLOR}\n"

table "Home Path" "${OE_HOME}"
table "Server Path" "${OE_HOME_EXT}"
table "Configuration file" "${OE_CONFIG}"

read -p "Proceed with this configuration? (y/n): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

##
###  WKHTMLTOPDF download links
## === Ubuntu Trusty x64 & x32 === (for other distributions please replace these two links,
## in order to have correct version of wkhtmltox installed, for a danger note refer to 
## https://www.odoo.com/documentation/8.0/setup/install.html#deb ):
WKHTMLTOX_X64=https://downloads.wkhtmltopdf.org/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb
WKHTMLTOX_X32=https://downloads.wkhtmltopdf.org/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-i386.deb

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update repositories ----"
sudo apt-get update

if [ "$UPDATE_SERVER" = true ]; then
    echo -e "\n---- Update Server ----"
    sudo apt-get upgrade -y
fi

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n---- Install PostgreSQL Server ----"

sudo apt-get install postgresql -y

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n--- Installing Python 3 + pip3 --"
sudo apt-get install python3 python3-pip

echo -e "\n---- Install tool packages ----"
sudo apt-get install wget git bzr python-pip gdebi-core -y

echo -e "\n---- Install python packages ----"
sudo apt-get install python-pypdf2 python-dateutil python-feedparser python-ldap python-libxslt1 python-lxml python-mako python-openid python-psycopg2 python-pybabel python-pychart python-pydot python-pyparsing python-reportlab python-simplejson python-tz python-vatnumber python-vobject python-webdav python-werkzeug python-xlwt python-yaml python-zsi python-docutils python-psutil python-mock python-unittest2 python-jinja2 python-pypdf python-decorator python-requests python-passlib python-pil -y
sudo pip3 install pypdf2 Babel passlib Werkzeug decorator python-dateutil pyyaml psycopg2 psutil html2text docutils lxml pillow reportlab ninja2 requests gdata XlsxWriter vobject python-openid pyparsing pydot mock mako Jinja2 ebaysdk feedparser xlwt psycogreen suds-jurko pytz pyusb greenlet xlrd 

echo -e "\n---- Install python libraries ----"
# This is for compatibility with Ubuntu 16.04. Will work on 14.04, 15.04 and 16.04
sudo apt-get install python3-suds

echo -e "\n--- Install other required packages"
sudo apt-get install node-clean-css -y
sudo apt-get install node-less -y
sudo apt-get install python-gevent -y

#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
  echo -e "\n---- Install wkhtml and place shortcuts on correct place for ODOO 11 ----"
  #pick up correct one from x64 & x32 versions:
  if [ "`getconf LONG_BIT`" == "64" ];then
      _url=$WKHTMLTOX_X64
  else
      _url=$WKHTMLTOX_X32
  fi
  sudo wget $_url
  sudo gdebi --n `basename $_url`
  sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
else
  echo -e "${DARKRED}Wkhtmltopdf isn't installed due to the choice of the user!${NOCOLOR}"
fi

echo -e "\n---- Create ODOO system user ----"
adduser --system --group --quiet --home=$OE_HOME  $OE_USER

echo -e "\n---- Create Log directory ----"
mkdir /var/log/$OE_USER
chown $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
sudo git clone --depth 1 --branch $OE_VERSION --single-branch https://www.github.com/odoo/odoo $OE_HOME_EXT/

if [ $IS_ENTERPRISE = "True" ]; then
    # Odoo Enterprise install!
    echo -e "\n--- Create symlink for node"
    sudo ln -s /usr/bin/nodejs /usr/bin/node
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise"
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise/addons"

    GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    while [[ $GITHUB_RESPONSE == *"Authentication"* ]]; do
        echo "------------------------WARNING------------------------------"
        echo "Your authentication with Github has failed! Please try again."
        printf "In order to clone and install the Odoo enterprise version you \nneed to be an offical Odoo partner and you need access to\nhttp://github.com/odoo/enterprise.\n"
        echo "TIP: Press ctrl+c to stop this script."
        echo "-------------------------------------------------------------"
        echo " "
        GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    done

    echo -e "\n---- Added Enterprise code under $OE_HOME/enterprise/addons ----"
    echo -e "\n---- Installing Enterprise specific libraries ----"
    sudo pip3 install num2words ofxparse
    sudo apt-get install nodejs npm
    sudo npm install -g less
    sudo npm install -g less-plugin-clean-css
fi

echo -e "\n---- Create custom module directory ----"
sudo mkdir $OE_HOME/custom
sudo mkdir $OE_HOME/custom/addons

echo -e "\n---- Setting permissions on home folder ----"
chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "* Create server config file"

sudo touch $OE_CONFIG
echo -e "* Creating server config file"
sudo su root -c "printf '[options] \n; This is the password that allows database operations:\n' >> ${OE_CONFIG}"
sudo su root -c "printf 'admin_passwd = ${OE_SUPERADMIN}\n' >> ${OE_CONFIG}"
sudo su root -c "printf 'db_host = False\n' >> ${OE_CONFIG}"
sudo su root -c "printf 'db_port = False\n' >> ${OE_CONFIG}"
sudo su root -c "printf 'db_user = ${OE_USER}\n' >> ${OE_CONFIG}"
sudo su root -c "printf 'db_password = False\n' >> ${OE_CONFIG}"
sudo su root -c "printf 'xmlrpc_port = ${OE_PORT}\n' >> ${OE_CONFIG}"
sudo su root -c "printf 'logfile = /var/log/${OE_USER}/${OE_PREFIX}.log\n' >> ${OE_CONFIG}"
if [ "$IS_ENTERPRISE" = true ]; then
    ADDONS_PATH="addons_path=${OE_HOME}/enterprise/addons,${OE_HOME_EXT}/addons"
    
else
    ADDONS_PATH="addons_path=${OE_HOME_EXT}/addons,${OE_HOME}/custom/addons"
    
fi
sudo su root -c "printf '${ADDONS_PATH}\n' >> ${OE_CONFIG}"
sudo chown $OE_USER:$OE_USER $OE_CONFIG
sudo chmod 640 $OE_CONFIG

#--------------------------------------------------
# Adding ODOO as a deamon (systemd)
#--------------------------------------------------

echo -e "* Create systemd file"

EXEC_FILE=$(find $OE_HOME_EXT -maxdepth 1 -executable -type f | head -n 1)

if [ "$EXEC_FILE" = "" ]; then
    echo -e "${RED}Could NOT find path to executable!${NOCOLOR}"
    read -p "Enter path to Odoo executable file: " EXEC_FILE
    
    if [ "$EXEC_FILE" = "" ]; then
        WARNING="${RED}Edit ${OE_SERVICE} to fill in executable file path before starting service!${NOCOLOR}"
    fi
    
fi


if [ "$WITH_DEMO_DATA" = true ];then
    EXEC_START="$EXEC_FILE --config=$OE_CONFIG"
    
else
    EXEC_START="$EXEC_FILE --config=$OE_CONFIG --without-demo=all"
    
fi

cat <<EOF > ~/$OE_SERVICE
[Unit]
Description=$OE_PREFIX Service
Requires=postgresql.service
After=network.target

[Service]
Type=simple
User=$OE_USER
WorkingDirectory=$OE_HOME
ExecStart=$EXEC_START

[Install]
WantedBy=multi-user.target
EOF

echo -e "* Systemd Service"
sudo mv ~/$OE_SERVICE /etc/systemd/system/$OE_SERVICE
sudo chmod 664 /etc/systemd/system/$OE_SERVICE
sudo chown root: /etc/systemd/system/$OE_SERVICE

echo -e "* Starting Odoo Service"
sudo systemctl start $OE_SERVICE
echo "-----------------------------------------------------------"
echo "Done! The Odoo server is up and running. Specifications:"
echo "Port: $OE_PORT"
echo "User service: $OE_USER"
echo "User PostgreSQL: $OE_USER"
echo "Code location: $OE_USER"
echo "Addons folder: $ADDONS_PATH"
echo "Start Odoo service: sudo systemctl start $OE_SERVICE"
echo "Stop Odoo service: sudo systemctl stop $OE_SERVICE"
echo "Restart Odoo service: sudo systemctl restart $OE_SERVICE"

[ -z "$WARNING" ] && echo "Warning: None" || echo "Warning: ${WARNING}"

echo "-----------------------------------------------------------"

cat << EOF
-----------------------------------------------------------
Done! The Odoo server is up and running. Specifications:
Port: $OE_PORT
User service: $OE_USER
User PostgreSQL: $OE_USER
Code location: $OE_USER
Addons folder: $OE_USER/$OE_CONFIG/addons/
Start Odoo service: sudo service $OE_CONFIG start
Stop Odoo service: sudo service $OE_CONFIG stop
Restart Odoo service: sudo service $OE_CONFIG restart
-----------------------------------------------------------
EOF
