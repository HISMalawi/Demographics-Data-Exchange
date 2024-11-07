---
output:
  html_document: default
  pdf_document: default
---
# DEMOGRAPHICS DATA EXCHANGE

DDE stands for Demographics Data Exchange. It was written in Ruby on Rails. Its main purpose is to manage patient IDs. 
It was built by Baobab Health Trust. 


##Requirements

* Ruby 3.2.0

* Rails 7.0.8

* MySQL 8

* Sidekiq 7.2.2

* Redis Server

##Dependancies

We recommend using a ruby version manager eg. rvm or rbenv.


##Setting Up

### DDE Proxy

The EASY way setup (Make sure there is a running Master)


* Open your terminal

* Clone DDE Application from github.
  ```bash
    git clone git@github.com:HISMalawi/Demographics-Data-Exchange.git dde4
  ```
  
* Enter into the root of your application by typing 
  ```bash
    cd dde4
  ```
* Run the following command and Answer the questions asked.
  ```bash
    ./bin/setup_dde_proxy_service.sh
  ```

The developer way:

* Open your terminal

* Clone DDE Application from github.
  ```bash
    git clone git@github.com:HISMalawi/Demographics-Data-Exchange.git dde4
  ```
  
* Enter into the root of your application by typing 
  ```bash
    cd dde4
  ```
  
* Copy all .yml.example files in config folder into .yml files.
  ```bash
    cp config/database.yml.example config/database.yml
    cp config/secrets.yml.example config/secrets.yml
    cp config/schedule.yml.example config/schedule.yml
    cp config/sidekiq.yml.example config/sidekiq.yml
  ```
  
* Configure your MySQL database in config/database.yml file respectively.
  Provide username, password, database name, host and port (if necessary)
  Use provided configs by DDE admnistrator to put under dde_sync_config.

* Run
  ```bash
    bundle install
  ```

If runing on a refresh database run
  * Run
  ```bash
    rails db:create db:migrate db:seed
  ```

If existing runing on an existing database run
  ```bash
    rails db:migrate db:seed
  ```
* Run the following command in your terminal (Replace the PORT with the port dde will run on):

  Create a service for DDE Proxy
  ```bash
   sudo vim /etc/systemd/system/dde4.service
  ```
  Add the following content to the file
  ```bash
    [Unit]
    Description=DDE4
    After=network.target

    [Service]
    Type=simple
    User=$USER

    WorkingDirectory=/var/www/dde4
    ExecStart=/bin/bash -lc 'CHANGE_TO_APPROPRIATE_RUBY_VERSION && bundle exec FULL_PUMA_PATH -C /var/www/dde4/config/puma.rb'
    Restart=always
    KillMode=process

    [Install]
    WantedBy=multi-user.target
  ```
  Notes:
  - CHANGE_TO_APPROPRIATE_RUBY_VERSION: Change this to the appropriate ruby version eg. `rvm use 3.2.0 or rbenv local 3.2.0`
  - FULL_PUMA_PATH: Change this to the full path to puma eg. `/var/www/dde4/bin/puma` you can get this by running `which puma`

And users to the application
  Application Users:
    1 -> EMR-API
      a -> Setup the config/application.yml in the EMR-API the URL, USERNAME and PASSWORD appropriately under dde:
        - url (put url dde is accessible on)
        - add username and password for all programs that are running on the site (These should be different for every program)
    2 -> DDE
       a -> Run the following command in your terminal replacing the URL with the one configured in the URL in dde config
         -> Copy the ACCESS_TOKEN to use in b
        ```bash
        curl --location --request POST 'URL/v1/login?username=admin&password=DDE_ADMIN_PASSWORD'
        ```

       b -> Create the users configured in the EMR-API and dde_sync_config using the following command replacing the (URL,TOKEN,PASSWORD, USERNAME AND LOCATION) for each user
           WHERE
            PASSWORD: password configured for the user in EMR-API
            USERNAME: username configured for the user in EMR-API
            LOCATION: location id for the site which is the integer configured in application global_property current_health_center_id
            URL: url for dde
            TOKEN: token produced at 2a

        ```bash
        curl --location --request POST 'URL/v1/add_user?username=USERNAME&password=PASSWORD&location=LOCATION' --header 'Authorization: TOKEN'
        ```
    3 -> Add the users to the dde_sync_config in the config/database.yml file
         Use the same process in 2 to create a user on the master and also a user on the master make sure they have the same attributes i.e username, password and location

###Setting up DDE Master

The process of setting up DDE Master is similar to setting up DDE Proxy. The only difference is that you will need to run to run you migration about with the key like in the example below.

```bash
  MASTER=true rails db:create db:migrate db:seed
```

This will create the npids table which you can populate with your preferred unique identifiers. We recommend using the ones that were initially generated. Otherwise for testing purposes you can use the following command to generate fake npids.

```bash
  rails r bin/npids_faker.rb
```

Voila! you got it.

Additions to this README are most welcome we want to make the process a painless as possible.
