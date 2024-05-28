#!/bin/bash

# Prompt user for the port number
read -p "Enter DDE port please : " port_number

# Prompt user for the username
read -p "Enter server username (e.g., meduser): " username

# Prompt user to select ruby version manager to use
read -sn1 -s -p "SELECT Ruby Version Manager to use
(1)Rbenv
(2)rvm" ruby_version_manager

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

# Run Bundle install
echo "Running Bundle install ..."
bundle install --local

# Get the path of Puma, Ruby, and ruby version manager
puma_path="$(which puma)"
ruby_path="$(which ruby)"

if [[ $ruby_version_manager == 1 ]]; then
    version_manager_path="$(which rbenv)"
    bundle_path="$(which bundle)"
    new_exec_start="/bin/bash -lc '$version_manager_path local 3.2.0 && $bundle_path exec puma -C /var/www/dde4/config/server/production.rb'"
else
    new_exec_start="/bin/bash -lc 'rvm use ruby-3.2.0 && bundle exec puma -C /var/www/dde4/config/server/production.rb'"
fi

# Create the service file with the new ExecStart directive
echo "Creating the new dde4.service file..."
sudo tee /etc/systemd/system/dde4.service > /dev/null << EOF
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
User=meduser
WorkingDirectory=/var/www/dde4
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
