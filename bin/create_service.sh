rail_modes=("test" "development" "production")
pattern=" |'"

actions() {
    tput setaf 6; read -p "Enter Application full path: " app_dir
}

service_loop(){
    read -p "Enter system name (use dashes instead of spaces or tabs): " service_name
}

actions
while [ ! -d $app_dir ]; do
    tput setaf 1; echo "===>Directory $app_dir DOES NOT EXISTS.<==="
    tput setaf 7;
    actions
done

app_core=$(grep -c processor /proc/cpuinfo)


read -p "Enter PORT: " app_port
read -p "Enter maximum number of threads to run: " app_threads
service_loop
while [[ $service_name =~ $pattern ]]; do
    tput setaf 1; echo "===>Please enter a system name without spaces or tabs. Use dashes instead<==="
    tput setaf 7;
    service_loop
done
read -p "Enter ruby version: " ruby
read -p "Enter puma path: " puma_dir

PS3="Please select a RAILS ENVIRONMENT: "
select mode in ${rail_modes[@]}
do
    if [ -z "$mode" ]; then
        tput setaf 1; echo "invalid option selected"
        tput setaf 7;
    else
        echo "$mode selected"
        break
    fi
done

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
threads_count = ENV.fetch('RAILS_MAX_THREADS') { $app_threads }
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

echo "Service fired up"
echo "Cleaning up"
rm ./${service_name}.service
rm ./${env}.rb
echo "Cleaning up done"

echo "complete"
