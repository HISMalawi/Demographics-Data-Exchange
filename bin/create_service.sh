#!/bin/bash

mode="production"
service_name="dde4"
ruby="2.5.3"
production_db="dde4_production"
host="0.0.0.0"


read -p "Enter DDE4 username: " username
read -p "Enter DDE4  password: "  password

actions() {
    tput setaf 6; read -p "Enter DDE4 full path or press Enter to default to (/var/www/dde4): " app_dir
    if [ -z "$app_dir" ]
    then
        app_dir="/var/www/dde4"
    fi

    cp ${app_dir}/config/database.yml.example $app_dir/config/database.yml
    cp ${app_dir}/config/secrets.yml.example  $app_dir/config/secrets.yml
    cp ${app_dir}/config/storage.yml.example $app_dir/config/storage.yml

    read -p "Site Location Id: " location
    read -p "Production mysql username: " db_username
    read -p "Production mysql password: " db_password
    read -p "Sync host: " sync_host
    read -p "Sync port: " sync_port
    read -p "Sync username: " sync_username
    read -p "Sync password: " sync_password
    

    sed -i -e "/^production:/,/database:/{/^\([[:space:]]*database: \).*/s//\1${production_db}/}" \
           -e "/^production:/,/username:/{/^\([[:space:]]*username: \).*/s//\1${db_username}/}" \
           -e "/^production:/,/password:/{/^\([[:space:]]*password: \).*/s//\1${db_password}/}" \
           -e "/^:dde_sync_config:/,/:host:/{/^\([[:space:]]*:host: \).*/s//\1${sync_host}/}" \
           -e "/^:dde_sync_config:/,/:port:/{/^\([[:space:]]*:port: \).*/s//\1${sync_port}/}" \
           -e "/^:dde_sync_config:/,/:username:/{/^\([[:space:]]*:username: \).*/s//\1${sync_username}/}" \
           -e "/^:dde_sync_config:/,/:password:/{/^\([[:space:]]*:password: \).*/s//\1${sync_password}/}" \
            ${app_dir}/config/database.yml

    }

actions
while [ ! -d $app_dir ]; do
    tput setaf 1; echo "===>Directory $app_dir DOES NOT EXISTS.<==="
    tput setaf 7;
    actions
done

read -p "Enter DDE PORT or press enter to default to (8050): " app_port

if [ -z "$app_port" ]
then
    app_port="8050"
fi


emr_config(){
    tput setaf 6; read -p "Enter BHT-EMR-API full path or press Enter to default to (/var/www/BHT-EMR-API): " emr_dir
    if [ -z "$emr_dir" ]
    then
        emr_dir="/var/www/BHT-EMR-API"
    fi

    sed -i -e "/^dde:/,/url:/{/^\([[:space:]]*url: \).*/s//\1${host}:${app_port}/}" $emr_dir/config/application.yml 
}

emr_config
while [ ! -d $emr_dir ]; do
    tput setaf 1; echo "===>Directory $emr_dir DOES NOT EXISTS.<==="
    tput setaf 7;
    emr_config
done

declare -A program_names
declare -A usernames
declare -A passwords

program_index=0
add_programs(){
    read -p "Enter EMR new program name: " program_name
    read -p "Enter $program_name username: " program_username
    read -p "Enter password for $program_username: " program_password

    program_names[$program_index]=$program_name
    usernames["$program_name"]=$program_username
    passwords["$program_name"]=$program_password

    read -p "Do you want to add another program(y/n): " choice
    if [[ $choice == "y" ]]; then
        program_index=$(($program_index+1))
        add_programs
    fi
}

add_programs
for program in "${program_names[@]}"; do
    sed -i "/dde:$/a\
    \  ${program}:" $emr_dir/config/application.yml 
    sed -i "/${program}:$/a\
    \    username: ${usernames[$program]}" $emr_dir/config/application.yml 
    sed -i "/${program}:$/a\
    \    password: ${passwords[$program]}"  $emr_dir/config/application.yml 
done

/bin/bash -lc "cd ${app_dir} && rvm use 2.5.3 && bundle install --local && RAILS_ENV=$mode rails db:create db:migrate db:seed"

app_core=$(grep -c processor /proc/cpuinfo)
puma_dir=$(which puma)

if [ -z "$puma_dir" ] 
then
    echo "puma path not found"
    echo "Please install ruby-railties"
    echo "sudo apt-get update -y"
    echo "sudo apt-get install -y ruby-railties"
    echo "Then try again"
    exit 0
fi

env=$mode


if systemctl --all --type service | grep -q "${service_name}.service";then
    echo "stopping service"
    sudo systemctl stop ${service_name}.service
    sudo systemctl disable ${service_name}.service
    echo "service stopped"
else
    echo "Setting up service"
fi

curr_dir=$(pwd)

echo "Writing the service"
echo "[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple

User=$USER

WorkingDirectory=$app_dir

Environment=RAILS_ENV=$env

ExecStart=/bin/bash -lc 'rvm use ${ruby} && ${puma_dir} -C ${app_dir}/config/server/${env}.rb'

Restart=always

KillMode=process

[Install]
WantedBy=multi-user.target" > ${service_name}.service

sudo cp ./${service_name}.service /etc/systemd/system

echo "Writing puma configuration"

[ ! -d ${app_dir}/config/server ] && mkdir ${app_dir}/config/server

echo "# Puma can serve each request in a thread from an internal thread pool.
# The threads method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads_count = ENV.fetch('RAILS_MAX_THREADS') { $app_core }
threads 2, threads_count

# Specifies the port that Puma will listen on to receive requests; default is 3000.
#
port        ENV.fetch('PORT') { $app_port }

# Specifies the environment that Puma will run in.
#
environment ENV.fetch('RAILS_ENV') { '$env' }

# Specifies the number of workers to boot in clustered mode.
workers ENV.fetch('WEB_CONCURRENCY') { $app_core }

# Use the preload_app! method when specifying a workers number.

preload_app!

# Allow puma to be restarted by rails restart command.
plugin :tmp_restart

rackup '${app_dir}/config.ru'" > ${env}.rb

sudo cp ./${env}.rb ${app_dir}/config/server/


echo "Firing the service up"

sudo systemctl daemon-reload
sudo systemctl enable ${service_name}.service
sudo systemctl start ${service_name}.service

echo "${service_name} Service fired up"
echo "Cleaning up"
rm ./${service_name}.service
rm ./${env}.rb


login_path="$host:$app_port/v1/login?username=$username&password=$password"

RESPONSE="$(sleep 5 && curl  --location --request POST $login_path)"

TOKEN=`echo "$RESPONSE" | grep -o '"access_token":"[^"]*' | grep -o '[^"]*$'`

for program in "${program_names[@]}"; do
    add_user_path="$host:$app_port/v1/add_user?username=${usernames[$program]}&password=${passwords[$program]}&location=$location"
    RESPONSE="$(sleep 2 && curl --location --request POST ${add_user_path} --header "Authorization: ${TOKEN}")"
done

add_user_path="$host:$app_port/v1/add_user?username=${sync_username}&password=${sync_password}&location=$location"
RESPONSE="$(sleep 2 && curl --location --request POST ${add_user_path} --header "Authorization: ${TOKEN}")"

echo "Users created"

echo "Sync cron job configured"
 
echo "Cleaning up done"

echo "completed"

echo "Service: ${service_name}"
echo "Port: ${app_port}"
echo "Environment: ${env}"
echo "---------------------------"
echo "*****SERVICE COMMANDS******"
echo "Service status"
echo "sudo service ${service_name} status"
echo "Start Service"
echo "sudo service ${service_name} start"
echo "Restart Service"
echo "sudo service ${service_name} restart "
echo "Stop Service"
echo "sudo service ${service_name} stop"
echo "Disable service"
echo "sudo systemctl disable ${service_name}"
echo "---------------------------"
echo "Thank You!"
sudo service ${service_name} status





