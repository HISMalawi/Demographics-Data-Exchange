---
output:
  html_document: default
  pdf_document: default
---
# DEMOGRAPHICS DATA EXCHANGE

DDE stands for Demographics Data Exchange. It was written in Ruby on Rails. Its main purpose is to manage patient IDs. 
It was built by Baobab Health Trust. 


##Requirements

* Ruby 2.5.3

* Rails 5.2.0

* MySQL 5.7

##Dependancies


##Setting Up

### DDE Proxy

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

  ```bash
    /bin/bash -lc 'cd /var/www/dde4/ && rvm use 2.5.3 && rails s -p PORT -b 0.0.0.0 -d'
  ```

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
* Run the following command:
    ```bash
    sudo sed -i 's/#TMPTIME=0/TMPTIME=0/g' /etc/default/rcS
    ```
* Set sync cronjob

    ```bash
    whenever --set 'environment=development' --update-crontab
    ```
* Setup cronjob to start DDE using
  ```bash
  crontab -e
  ```
  Add the following line to the crontab (Replace the PORT with the port dde will run on):
  ```bash
  @reboot /bin/bash -lc 'cd /var/www/dde4/ && rvm use 2.5.3 && rails s -p PORT -b 0.0.0.0 -d'
  ```


###Setting up DDE Master

1. Initialize database by typing the following in the command line
   ```bash
     rake db:create db:migrate db:seed
   ```
2. Load MySQL national ids dump into DDE MySQL npids table.

3. You can now start DDE master server.
   ```bash
    rails s -p <PORT_NUMBER> -b 0.0.0.0 -d
   ```
4. Setup cronjob to start DDE using
  ```bash
  crontab -e
  ```
5. Add the following line to the crontab (Replace the PORT with the port dde will run on):
  ```bash
  @reboot /bin/bash -lc 'cd /var/www/dde4/ && rvm use 2.5.3 && rails s -p PORT -b 0.0.0.0 -d'
  ```
