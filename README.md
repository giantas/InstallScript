# [Odoo](https://www.odoo.com "Odoo's Homepage") Install Script

This script is based on the install script from Yenthe V.G (https://github.com/Yenthe666/InstallScript)
but goes a bit further and has been improved. 

This script can be safely used in a multi-odoo code base server because the default Odoo port is changed BEFORE the Odoo is started.

## Installation procedure

### 1. Download the script:
```
sudo wget https://raw.githubusercontent.com/giantas/InstallScript/11.0/odoo_install.sh
```
### 2. Modify the parameters as you wish.
In the [config](config.sh), modify parameters as you wish.

**NOTE**: User *true* or *false* where appropriate

### 3. Make the script executable
```
sudo chmod +x odoo_install.sh
```
### 4. Execute the script:
```
./odoo_install.sh
```
