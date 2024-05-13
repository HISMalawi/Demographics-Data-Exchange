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
echo "Stopping the service running on port 8050..."
sudo systemctl stop dde4.service
else
echo "No service found running on port 8050."
fi

# Kill the process using port 8050
echo "Killing the process using port 8050..."
sudo fuser -k 8050/tcp

# Remove the vendor folder and Gemfile.lock
echo "Removing vendor folder and Gemfile.lock"
sudo rm -rf vendor/
sudo rm -f Gemfile.lock

#Run Bundle install
echo "RUnning Bundle install ..."
bundle install

#Get the path of Puma, Ruby and ruby version manager
puma_path="$( bash -lc 'which puma')"
ruby_path="$( bash -lc 'which ruby')"

if [ -z "$puma_path"]; then
    puma_path="puma"
fi


if [[ $ruby_version_manager  == 1 ]]; then
   version_manager_path="$( bash -lc 'which rbenv')"
   bundle_path="$(bash -lc 'which bundle')"
   new_exec_start="'$version_manager_path local 3.2.0 && $bundle_path exec $puma_path -C /var/www/dde4/config/server/production.rb'"
else
   new_exec_start="/bin/bash -lc 'rvm  use 3.2.0 && bundle exec $puma_path -C /var/www/dde4/config/server/production.rb'"
fi



# Edit the ExecStart directive in the dde4.service file
echo "Editing the ExecStart directive in dde4.service..."
echo "Changing to Ruby 3.2.0"
# Define the new ExecStart value
#'/home/ubuntu/.rbenv/bin/rbenv local 3.2.0 && /home/ubuntu/.rbenv/shims/bundle exec puma -C /var/www/dde4/config/server/production.rb'



# Commenting out all occurrences of ExecStart lines
echo "Commenting out all occurrences of ExecStart lines in dde4.service..."
sudo sed -i '/^ExecStart=/ s|^ExecStart=|#&|' /etc/systemd/system/dde4.service

# Add the new ExecStart after commenting the old one
sudo sed -i "/^#ExecStart=/ a ExecStart=$new_exec_start" /etc/systemd/system/dde4.service
 

# Reload daemon
echo "Now reloading the service..."
sudo systemctl daemon-reload

# Restart service
echo "Restarting the service"
sudo systemctl restart dde4.service

echo "Finished setting up!!"

 

