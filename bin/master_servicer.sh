#!/bin/bash

#initializing service constants
MODE="production"
SERVICE_NAME="dde4"
RUBY="2.5.3"
PRODUCTION_DB="dde4_master_production"

#Configures DDE database YAML 
actions() {
    
    #Gets DDE directory entered or default 
    tput setaf 6; read -p "Enter DDE4 full path or press Enter to default to (/var/www/dde4_master): " APP_DIR
    if [ -z "$APP_DIR" ]
    then
        APP_DIR="/var/www/dde4_master"
    fi

    read -p "Enter DDE4 host IP Address: " HOST

    #Copying YAML files
    cp ${APP_DIR}/config/secrets.yml.example  $APP_DIR/config/secrets.yml
    cp ${APP_DIR}/config/storage.yml.example $APP_DIR/config/storage.yml

}

actions

#Unless DDE Directory exists call method to set DDE directory
while [ ! -d $APP_DIR ]; do
    tput setaf 1; echo "===>Directory $APP_DIR DOES NOT EXISTS.<==="
    tput setaf 7;
    actions
done

# Prompts for DDE PORT or Defaults to PORT 8050
read -p "Enter DDE PORT or press enter to default to (8050): " APP_PORT
if [ -z "$APP_PORT" ]
then
    APP_PORT="9000"
fi



#Runs rails bundle install, creates database, migration and seed
/bin/bash -lc "cd ${APP_DIR} && rvm use 2.5.3 && bundle install --local && RAILS_ENV=$MODE rails db:create db:migrate db:seed"

#Get number of CPU cores
APP_CORE=$(grep -c processor /proc/cpuinfo)

#Fetches puma directory
PUMA_DIR=$(which puma)

#Exits if puma does not exist and recommends installation of ruby railties
if [ -z "$PUMA_DIR" ] 
then
    echo "puma path not found"
    echo "Please install ruby-railties"
    echo "sudo apt-get update -y"
    echo "sudo apt-get install -y ruby-railties"
    echo "Then try again"
    exit 0
fi

ENV=$MODE

#Stops and disables current DDE service
if systemctl --all --type service | grep -q "${SERVICE_NAME}.service";then
    echo "stopping service"
    sudo systemctl stop ${SERVICE_NAME}.service
    sudo systemctl disable ${SERVICE_NAME}.service
    echo "service stopped"
else
    echo "Setting up service"
fi

CURR_DIR=$(pwd)

echo "Writing the service"
echo "[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple

User=$USER

WorkingDirectory=$APP_DIR

Environment=RAILS_ENV=$ENV

ExecStart=/bin/bash -lc 'rvm use ${RUBY} && ${PUMA_DIR} -C ${APP_DIR}/config/server/${ENV}.rb'

Restart=always

KillMode=process

[Install]
WantedBy=multi-user.target" > ${SERVICE_NAME}.service

sudo cp ./${SERVICE_NAME}.service /etc/systemd/system

echo "Writing puma configuration"

[ ! -d ${APP_DIR}/config/server ] && mkdir ${APP_DIR}/config/server

echo "# Puma can serve each request in a thread from an internal thread pool.
# The threads method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads_count = ENV.fetch('RAILS_MAX_THREADS') { $APP_CORE }
threads 2, threads_count

# Specifies the port that Puma will listen on to receive requests; default is 3000.
#
port        ENV.fetch('PORT') { $APP_PORT }

# Specifies the environment that Puma will run in.
#
environment ENV.fetch('RAILS_ENV') { '$ENV' }

# Specifies the number of workers to boot in clustered mode.
workers ENV.fetch('WEB_CONCURRENCY') { $APP_CORE }

# Use the preload_app! method when specifying a workers number.

preload_app!

# Allow puma to be restarted by rails restart command.
plugin :tmp_restart

rackup '${APP_DIR}/config.ru'" > ${ENV}.rb

sudo cp ./${ENV}.rb ${APP_DIR}/config/server/


echo "Firing the service up"

#Starts service
sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME}.service
sudo systemctl start ${SERVICE_NAME}.service

echo "${SERVICE_NAME} Service fired up"
echo "Cleaning up"
rm ./${SERVICE_NAME}.service
rm ./${ENV}.rb

# Updates crontab for DDE sync cron job
whenever --set "environment=${ENV}" --update-crontab

echo "Users created successfully"

echo "Sync cron job configured"
 
echo "Cleaning up done"

echo "completed"

#Displaying summary of service
echo "Service: ${SERVICE_NAME}"
echo "Port: ${APP_PORT}"
echo "Environment: ${ENV}"
echo "---------------------------"

echo "*****SERVICE COMMANDS*******"
echo "Service status"
echo "sudo service ${SERVICE_NAME} status"
echo "Start Service"
echo "sudo service ${SERVICE_NAME} start"
echo "Restart Service"
echo "sudo service ${SELEVICE_NAME} restart "
echo "Stop Service"
echo "sudo service ${SERVICE_NAME} stop"
echo "Disable service"
echo "sudo systemctl disable ${SERVICE_NAME}"
echo "---------------------------"
echo "Thank You!"
sudo service ${SERVICE_NAME} status

