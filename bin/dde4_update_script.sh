#!/bin/bash

#Gets DDE directory entered or default 
tput setaf 6; read -p "Enter DDE4 full path or press Enter to default to (/var/www/dde4): " APP_DIR
if [ -z "$APP_DIR" ]
then
    APP_DIR="/var/www/dde4"
fi



# Run the Rails runner with your sync script
echo "🔄 Adding missing locations sync..."

SQL_FILE="$APP_DIR/db/meta_data/missing_locations.sql"

# Check if file exists
if [ ! -f "$SQL_FILE" ]; then
    tput setaf 1; echo "❌ SQL file not found at $SQL_FILE"; tput sgr0
    exit 1
fi


# Extract production block
PROD_BLOCK=$(sed -n '/^production:/,/^[^[:space:]]/p' "$APP_DIR/config/database.yml")

DB_NAME=$(echo "$PROD_BLOCK" | grep "database:" | sed 's/.*database:[[:space:]]*//')
DB_USER=$(echo "$PROD_BLOCK" | grep "username:" | sed 's/.*username:[[:space:]]*//')
DB_PASS=$(echo "$PROD_BLOCK" | grep "password:" | sed 's/.*password:[[:space:]]*//')

if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ]; then
    tput setaf 1; echo "❌ Could not extract DB credentials from $APP_DIR/config/database.yml"; tput sgr0
    echo "👉 Debug info:"
    echo "DB_NAME='$DB_NAME'"
    echo "DB_USER='$DB_USER'"
    echo "DB_PASS='$DB_PASS'"
    exit 1
fi

echo "🔄 Adding missing locations sync into $DB_NAME..."
mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SQL_FILE"

if [ $? -eq 0 ]; then
    tput setaf 2; echo "✅ Import completed successfully"; tput sgr0
else
    tput setaf 1; echo "❌ Import failed"; tput sgr0
fi

username="$(whoami)"
# username="emr-user"

environment=${environment:-production}

# Check if the file exists and extract the port number
if [ -f "$APP_DIR/config/server/production.rb" ]; then
    port_number=$(grep  -rn 'port\s*ENV' "$APP_DIR/config/server/production.rb" | awk -F '[{}]' '{print $2}')
elif [ -f "$APP_DIR/config/puma.rb" ]; then
    port_number=$(grep  -rn 'port\s*ENV' "$APP_DIR/config/puma.rb" | awk -F '[{}]' '{print $2}')
fi


# Prompt user to select Ruby version manager to use
echo -e "\nSELECT Ruby Version Manager to use"
echo "1) Rbenv"
echo "2) RVM"
read -sn1 -s ruby_version_manager

# Copying YAML files
echo -e '\n\e[1;33mCopying Database YAML file..\e[0m'

# Backing up current database.yml file
cp ${APP_DIR}/config/database.yml $APP_DIR/config/database.backup.yml

# Function to read a value from YAML file
read_yaml() {
    local section=$1
    local key=$2
    grep -A 10 "^${section}:" ${APP_DIR}/config/database.yml.example | grep "^  ${key}:" | awk '{print $2}'
}

# Read the production database username and password
# PRODUCTION_DB=$(read_yaml "production" "database")
# DDE_DB_USERNAME=$(read_yaml "production" "username")
# DDE_DB_PASSWORD=$(read_yaml "production" "password")

# Read the dde_sync_config username and password
# SYNC_USERNAME=$(read_yaml ":dde_sync_config" ":username")
SYNC_BATCHSIZE=10_000
SYNC_PROTOCOL=$(read_yaml ":dde_sync_config" ":protocol")
SYNC_HOST=$(read_yaml ":dde_sync_config" ":host")


# Update the current database.yml with extracted values
sed -i -e "s/^:batch_size:[[:space:]]*'[^']*'/:batch_size:\n  :batch: ${SYNC_BATCHSIZE}/" \
    -e "/^:dde_sync_config:/,/^[^ ]/{/^\([[:space:]]*:protocol: \).*/s//\1${SYNC_PROTOCOL}/}" \
    -e "/^:dde_sync_config:/,/^[^ ]/{/^\([[:space:]]*:host: \).*/s//\1${SYNC_HOST}/}" \
    -e "/^:dde_sync_config:/,/^[^ ]/{/^\([[:space:]]*:port: \).*/s/^/#/}" \
    "${APP_DIR}/config/database.yml"


cp ${APP_DIR}/config/sidekiq.yml.example $APP_DIR/config/sidekiq.yml
cp ${APP_DIR}/config/schedule.yml.example $APP_DIR/config/schedule.yml
sudo chmod 777 $APP_DIR/config/sidekiq.yml
sudo chmod 777 $APP_DIR/config/schedule.yml

# Kill the process using port 8050
echo "Killing the process using port $port_number..."
sudo fuser -k $port_number/tcp

# Remove the vendor folder and Gemfile.lock
echo "Removing vendor folder and Gemfile.lock"
sudo rm -rf vendor/bundle/ruby/2.5.3
sudo rm -f Gemfile.lock

# Run Bundle install
echo "Running Bundle install ..."
cd $APP_DIR && bundle install --local



# Get the path of Puma, Ruby, and Ruby version manager
puma_path="$(which puma)"
ruby_path="$(which ruby)"
rails_path="$(which rails)"
bundle_path="$(which bundle)"
# bundle_path="/home/$username/.rbenv/shims/bundle"

echo "Run any pending  migrations"
cd $APP_DIR && RAILS_ENV=production $rails_path db:migrate

echo 'Precompile assets'
cd $APP_DIR && RAILS_ENV=production $rails_path assets:clobber
cd $APP_DIR && RAILS_ENV=production $rails_path assets:precompile
cd $APP_DIR && RAILS_ENV=production $rails_path tailwindcss:build


if [[ $ruby_version_manager == 1 ]]; then
    version_manager_path="/home/$username/.rbenv/bin/rbenv"
    new_exec_start="/bin/bash -lc '$version_manager_path local 3.2.0 && $bundle_path exec $puma_path -C $APP_DIR/config/puma.rb'"
else
    new_exec_start="/bin/bash -lc 'rvm use ruby-3.2.0 && $bundle_path exec $puma_path -C $APP_DIR/config/puma.rb'"
fi

sidekiq_exec_start="/bin/bash -lc '$bundle_path exec sidekiq -e production'"

# Calculate half of the total cores, rounding down
cores=$(nproc)/2

# Create the Puma configuration file
cat <<EOL > $APP_DIR/config/puma.rb
# Puma can serve each request in a thread from an internal thread pool..
# The \`threads\` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

# Specifies the \`port\` that Puma will listen on to receive requests; default is 3000.
#
port ENV.fetch("PORT") { ${port_number} }


# Specifies the \`environment\` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV") { "${environment}" }

# Specifies the number of \`workers\` to boot in clustered mode.
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max \`threads\` * \`workers\`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#

workers ENV.fetch("WEB_CONCURRENCY") { $cores }

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
Environment="DDE_HOST_URL=http://127.0.0.1:8050"
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

# Check Puma service status
if systemctl is-active --quiet dde4.service; then
    echo "✅ dde4 service is running successfully."
else
    echo "❌ dde4 service failed to start. Check logs:"
    sudo journalctl -u dde4.service --no-pager --lines=20
    exit 1
fi

echo 'Configure DDE Sidekiq service'
SERVICE_FILE="/etc/systemd/system/dde4_sidekiq.service"

# Create the service file
cat <<EOF | sudo tee $SERVICE_FILE > /dev/null
[Unit]
Description=Sidekiq
After=syslog.target network.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR
Environment="DDE_HOST_URL=http://127.0.0.1:8050"
Environment="RAILS_ENV=production"
ExecStart=$sidekiq_exec_start
User=$username
UMask=0002
RestartSec=1
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable dde4_sidekiq
sudo systemctl start dde4_sidekiq
sudo systemctl restart dde4_sidekiq

# Check Sidekiq service status
if systemctl is-active --quiet dde4_sidekiq; then
    echo "✅ Sidekiq service is running successfully."
else
    echo "❌ Sidekiq service failed to start. Check logs:"
    sudo journalctl -u dde4_sidekiq --no-pager --lines=20
    exit 1
fi

echo "🎉 Finished setting up!"
exit 0
