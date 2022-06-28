#!/bin/bash

#Initializing service constants
MODE="production"
SERVICE_NAME="dde4"
RUBY="2.5.3"
PRODUCTION_DB="dde4_production"

#Prompts entering of user details used for aunthentication
read -p "Enter DDE4  username: " USERNAME
read -p "Enter DDE4  password: "  PASSWORD

#Configures DDE database YAML 
actions() {
    
    #Gets DDE directory entered or default 
    tput setaf 6; read -p "Enter DDE4 full path or press Enter to default to (/var/www/dde4): " APP_DIR
    if [ -z "$APP_DIR" ]
    then
        APP_DIR="/var/www/dde4"
    fi

    read -p "Enter DDE4 host IP Address: " HOST

    #Copying YAML files
    cp ${APP_DIR}/config/database.yml.example $APP_DIR/config/database.yml
    cp ${APP_DIR}/config/secrets.yml.example  $APP_DIR/config/secrets.yml
    cp ${APP_DIR}/config/storage.yml.example $APP_DIR/config/storage.yml

    read -p "Site Location Id: " LOCATION

    #Gets production database password and username    
    read -p "Production mysql username: " DDE_DB_USERNAME
    read -p "Production mysql password: " DDE_DB_PASSWORD

    #Gets SYNC with master configurations
    read -p "Sync host: " SYNC_HOST
    read -p "Sync port: " SYNC_PORT
    read -p "Sync username: " SYNC_USERNAME
    read -p "Sync password: " SYNC_PASSWORD

    SYNC_USERNAME="${SYNC_USERNAME}_${LOCATION}"
    
    #Updates YAML file with new configurations
    sed -i -e "/^production:/,/database:/{/^\([[:space:]]*database: \).*/s//\1${PRODUCTION_DB}/}" \
           -e "/^production:/,/username:/{/^\([[:space:]]*username: \).*/s//\1${DDE_DB_USERNAME}/}" \
           -e "/^production:/,/password:/{/^\([[:space:]]*password: \).*/s//\1${DDE_DB_PASSWORD}/}" \
           -e "/^:dde_sync_config:/,/:host:/{/^\([[:space:]]*:host: \).*/s//\1${SYNC_HOST}/}" \
           -e "/^:dde_sync_config:/,/:port:/{/^\([[:space:]]*:port: \).*/s//\1${SYNC_PORT}/}" \
           -e "/^:dde_sync_config:/,/:username:/{/^\([[:space:]]*:username: \).*/s//\1${SYNC_USERNAME}/}" \
           -e "/^:dde_sync_config:/,/:password:/{/^\([[:space:]]*:password: \).*/s//\1${SYNC_PASSWORD}/}" \
            ${APP_DIR}/config/database.yml
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
    APP_PORT="8050"
fi


emr_config(){

    read -p "Are you running BHT-EMR and DDE4 on same server?(y/n) " SAME_SERVER

    tput setaf 6; read -p "Enter BHT-EMR-API full path or press Enter to default to (/var/www/BHT-EMR-API): " EMR_DIR
    if [ -z "$EMR_DIR" ]
    then
        EMR_DIR="/var/www/BHT-EMR-API"
    fi

    if [[ $SAME_SERVER == "y" ]]; then
      EMR_APP_YML_PATH=$EMR_DIR/config/application.yml
      read -p "Enter EMR database: " EMR_DATABASE
      read -p "Enter EMR database username: " EMR_DB_USERNAME
      read -p "Enter EMR database password: " EMR_DB_PASSWORD 
      sed -i -e "/^dde:/,/url:/{/^\([[:space:]]*url: \).*/s//\1${HOST}:${APP_PORT}/}" $EMR_DIR/config/application.yml

    else
 
      read -p "Enter IP ADDRESS of server BHT-EMR is running on: "  EMR_APIADDRESS
      read -p "Enter username for ${EMR_APIADDRESS}: " SERVER_USERNAME

      EMR_APP_YML_PATH=$EMR_DIR/config/application.yml
      echo "${APP_DIR}"
      scp "$SERVER_USERNAME@$EMR_APIADDRESS:$EMR_APP_YML_PATH" ${APP_DIR}/config/
      sed -i -e "/^dde:/,/url:/{/^\([[:space:]]*url: \).*/s//\1${HOST}:${APP_PORT}/}" ${APP_DIR}/config/application.yml
    fi
}

emr_config

declare -A PROGRAM_NAMES
declare -A PROGRAM_USERNAMES
declare -A PROGRAM_PASSWORDS

PROGRAM_INDEX=0

#Iterates through programs
get_programs(){
      read -p "Enter EMR program name: " PROGRAM_NAME


    if [[ $SAME_SERVER == "y" ]]; then
        QUERY="SELECT EXISTS(SELECT * FROM program WHERE 
            name = UPPER('${PROGRAM_NAME}') and retired = false);"
        RESULT=`mysql --user=$EMR_DB_USERNAME --password=$EMR_DB_PASSWORD -s -N $EMR_DATABASE -e "${QUERY}"`

        if [[ $RESULT != 1 ]]; then
          echo "program does not exist"
          get_programs
        fi
    fi

    read -p "Enter $PROGRAM_NAME username: " PROGRAM_USERNAME
    read -p "Enter password for $PROGRAM_USERNAME user: " PROGRAM_PASSWORD

    PROGRAM_NAMES[$PROGRAM_INDEX]=$PROGRAM_NAME
    PROGRAM_USERNAMES["$PROGRAM_NAME"]=$PROGRAM_USERNAME
    PROGRAM_PASSWORDS["$PROGRAM_NAME"]=$PROGRAM_PASSWORD

    read -p "Do you want to add another program(y/n): " CHOICE
    if [[ $CHOICE == "y" ]]; then
        PROGRAM_INDEX=$(($PROGRAM_INDEX+1))
        get_programs
    fi
}

get_programs

add_remote_programs(){
    for PROGRAM in "${PROGRAM_NAMES[@]}"; do

        if grep -E "${PROGRAM}:" ${APP_DIR}/config/application.yml
        then
            sed -i -e "/${PROGRAM}:/,/username:/{/^\([[:space:]]*username: \).*/s//\1${PROGRAM_USERNAMES[$PROGRAM]}/}" ${APP_DIR}/config/application.yml
            sed -i -e "/${PROGRAM}/,/password:/{/^\([[:space:]]*password: \).*/s//\1${PROGRAM_PASSWORDS[$PROGRAM]}/}" ${APP_DIR}/config/application.yml
        else
        sed -i "/dde:$/a\
        \  ${PROGRAM}:"  ${APP_DIR}/config/application.yml
        sed -i "/${PROGRAM}:$/a\
        \    password: ${PROGRAM_PASSWORDS[$PROGRAM]}"  ${APP_DIR}/config/application.yml
        sed -i "/${PROGRAM}:$/a\
        \    username: ${PROGRAM_USERNAMES[$PROGRAM]}"  ${APP_DIR}/config/application.yml
        fi
    done

    scp ${APP_DIR}/config/application.yml "$SERVER_USERNAME@$EMR_APIADDRESS:${EMR_APP_YML_PATH}" 
    sudo rm ${APP_DIR}/config/application.yml
}


add_local_programs(){
    for PROGRAM in "${PROGRAM_NAMES[@]}"; do

        if grep -E "${PROGRAM}:" $EMR_APP_YML_PATH
        then
            sed -i -e "/${PROGRAM}:/,/username:/{/^\([[:space:]]*username: \).*/s//\1${PROGRAM_USERNAMES[$PROGRAM]}/}" $EMR_APP_YML_PATH
            sed -i -e "/${PROGRAM}/,/password:/{/^\([[:space:]]*password: \).*/s//\1${PROGRAM_PASSWORDS[$PROGRAM]}/}" $EMR_APP_YML_PATH
        else
        sed -i "/dde:$/a\
        \  ${PROGRAM}:" $EMR_APP_YML_PATH 
        sed -i "/${PROGRAM}:$/a\
        \    password: ${PROGRAM_PASSWORDS[$PROGRAM]}"  $EMR_APP_YML_PATH
        sed -i "/${PROGRAM}:$/a\
        \    username: ${PROGRAM_USERNAMES[$PROGRAM]}" $EMR_APP_YML_PATH
        fi
    done
}

if [[ $SAME_SERVER == "y" ]]; then
    add_local_programs
else
    add_remote_programs
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

#Building path for login using DDE username and password
LOGIN_PATH="$HOST:$APP_PORT/v1/login?username=$USERNAME&password=$PASSWORD"

#Login Request Sent
RESPONSE="$(sleep 5 && curl  --location --request POST $LOGIN_PATH)"

#Fetchs token from response object
TOKEN=`echo "$RESPONSE" | grep -o '"access_token":"[^"]*' | grep -o '[^"]*$'`

if [ -z "$TOKEN" ]
then
    echo "Failed to login"
    exit 0
else
    #Adds program users 
    for PROGRAM in "${PROGRAM_NAMES[@]}"; do
        ADD_USER_PATH="$HOST:$APP_PORT/v1/add_user?username=${PROGRAM_USERNAMES[$PROGRAM]}&password=${PROGRAM_PASSWORDS[$PROGRAM]}&location=$LOCATION"
        RESPONSE="$(sleep 2 && curl --location --request POST ${ADD_USER_PATH} --header "Authorization: ${TOKEN}")"
    done

    #Adds DDE sync user
    ADD_USER_PATH="$HOST:$APP_PORT/v1/add_user?username=${SYNC_USERNAME}&password=${SYNC_PASSWORD}&location=$LOCATION"
    RESPONSE="$(sleep 2 && curl --location --request POST ${ADD_USER_PATH} --header "Authorization: ${TOKEN}")"
fi


#Authentication with master
LOGIN_PATH="http://$SYNC_HOST:$SYNC_PORT/v1/login?username=$USERNAME&password=$PASSWORD"

RESPONSE="$(sleep 6 && curl  --location --request POST $LOGIN_PATH)"

TOKEN=`echo "$RESPONSE" | grep -o '"access_token":"[^"]*' | grep -o '[^"]*$'`


if [ -z "$TOKEN" ]
then
    echo "Failed to login"
    exit 0
else
    #Creating Sync User
    ADD_USER_PATH="http://$SYNC_HOST:$SYNC_PORT/v1/add_user?username=${SYNC_USERNAME}&password=${SYNC_PASSWORD}&location=$LOCATION"
    RESPONSE="$(sleep 2 && curl --location --request POST ${ADD_USER_PATH} --header "Authorization: ${TOKEN}")"
fi


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
