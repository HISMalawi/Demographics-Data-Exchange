#!/bin/bash

PRODUCTION_DB="dde4_production"


#Gets DDE directory entered or default 
tput setaf 6; read -p "Enter DDE4 full path or press Enter to default to (/var/www/dde4): " APP_DIR
if [ -z "$APP_DIR" ]
then
    APP_DIR="/var/www/dde4"
fi

# Prompt user for the port number
read -p "Enter DDE port please : " port_number

# Prompt user for the username
read -p "Enter server username (e.g., meduser): " username

# Prompt the user for enviroment and port
read -p "Enter the environment (e.g., development, production): " environment

environment=${environment:-development}
port_number=${port_number:-3000}

# Prompt user to select ruby version manager to use
read -sn1 -s -p "SELECT Ruby Version Manager to use
(1)Rbenv
(2)rvm" ruby_version_manager

#Copying YAML files
echo $'\e[1;33m'Copying Database YAML file..$'\e[0m'

#Gets production database password and username    
read -p "Production mysql username: " DDE_DB_USERNAME
read -p "Production mysql password: " DDE_DB_PASSWORD

#Gets SYNC with master configurations
read -p "Enter site location identifier: " LOCATION
read -p "Sync host: " SYNC_HOST
read -p "Sync port: " SYNC_PORT
read -p "Sync username: " SYNC_USERNAME
read -p "Sync password: " SYNC_PASSWORD

SYNC_USERNAME="${SYNC_USERNAME}_${LOCATION}"

# Copying  database.yml.example agan because formating was changed for ruby 3.2.0
cp ${APP_DIR}/config/database.yml.example $APP_DIR/config/database.yml

#Updates YAML file with new configurations
echo $'\e[1;33m'Updating new configurations..$'\e[0m'
sed -i -e "/^production:/,/database:/{/^\([[:space:]]*database: \).*/s//\1${PRODUCTION_DB}/}" \
        -e "/^production:/,/username:/{/^\([[:space:]]*username: \).*/s//\1${DDE_DB_USERNAME}/}" \
        -e "/^production:/,/password:/{/^\([[:space:]]*password: \).*/s//\1${DDE_DB_PASSWORD}/}" \
        -e "/^:dde_sync_config:/,/:host:/{/^\([[:space:]]*:host: \).*/s//\1${SYNC_HOST}/}" \
        -e "/^:dde_sync_config:/,/:port:/{/^\([[:space:]]*:port: \).*/s//\1${SYNC_PORT}/}" \
        -e "/^:dde_sync_config:/,/:username:/{/^\([[:space:]]*:username: \).*/s//\1${SYNC_USERNAME}/}" \
        -e "/^:dde_sync_config:/,/:password:/{/^\([[:space:]]*:password: \).*/s//\1${SYNC_PASSWORD}/}" \
        ${APP_DIR}/config/database.yml


# Then Check if the service is running on port 8050
if lsof -Pi :$port_number -sTCP:LISTEN -t >/dev/null ; then
    # If the service is running, stop it
    echo "Stopping the service running on port $port_number..."
    sudo systemctl stop dde4.service
else
    echo "No service found running on port $port_number."
fi

# Kill the process using port 8050
echo "Killing the process using port $port_number..."
sudo fuser -k $port_number/tcp

# Remove the vendor folder and Gemfile.lock
echo "Removing vendor folder and Gemfile.lock"
sudo rm -rf vendor/bundle/ruby/2.5.3
sudo rm -f Gemfile.lock
sudo rm 
# Run Bundle install
echo "Running Bundle install ..."
bundle install --local


# Get the path of Puma, Ruby, and ruby version manager
puma_path="$(which puma)"
ruby_path="$(which ruby)"

if [[ $ruby_version_manager == 1 ]]; then
    version_manager_path="$(which rbenv)"
    bundle_path="$(which bundle)"
    new_exec_start="/bin/bash -lc '$version_manager_path local 3.2.0 && $bundle_path exec puma -C $APP_DIR/config/puma.rb'"
else
    new_exec_start="/bin/bash -lc 'rvm use 3.2.0 && bundle exec puma -C $APP_DIR/config/puma.rb'"
fi


# Create the Puma configuration file
cat <<EOL > $APP_DIR/config/puma.rb
# Puma can serve each request in a thread from an internal thread pool.
# The \`threads\` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

# Specifies the \`port\` that Puma will listen on to receive requests; default is 3000.
#
port        ENV.fetch("PORT") { ${port_number} }

# Specifies the \`environment\` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV") { "${environment}" }

# Specifies the number of \`workers\` to boot in clustered mode.
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max \`threads\` * \`workers\`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
# workers ENV.fetch("WEB_CONCURRENCY") { 1 }

# Use the \`preload_app!\` method when specifying a \`workers\` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
# preload_app!

# Allow puma to be restarted by \`rails restart\` command.
plugin :tmp_restart
EOL

echo "Puma configuration file created successfully"

# Create the service file with the new ExecStart directive
echo "Creating the new dde4.service file..."
sudo tee /etc/systemd/system/dde4.service > /dev/null << EOF
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
User=$username
WorkingDirectory=$APP_DIR
Environment=RAILS_ENV=production
ExecStart=$new_exec_start
Restart=always
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

# Reload daemon
echo "Now reloading the service..."
sudo systemctl daemon-reload

# Restart service
echo "Restarting the service"
sudo systemctl restart dde4.service

echo "Finished setting up!!"
