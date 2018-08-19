#! /usr/bin/env bash

. config.sh

OE_HOME="/$OE_USER"
OE_HOME_EXT="/$OE_USER/${OE_USER}-server"
OE_PREFIX="${OE_USER}-server"
OE_CONFIG="/etc/${OE_PREFIX}.conf"
OE_SERVICE="${OE_USER}.service"

sudo rm -rf $OE_HOME $OE_CONFIG /etc/systemd/system/${OE_SERVICE} /var/log/${OE_USER}
sudo userdel $OE_USER
sudo groupdel $OE_USER
sudo su - postgres -c "dropdb $DATABASE_NAME; dropuser $OE_USER;" 2> /dev/null || true
