---
output:
  html_document: default
  pdf_document: default
---
# DEMOGRAPHICS DATA EXCHANGE

DDE stands for Demographics Data Exchange. It was written in Ruby on Rails. Its main purpose is to manage patient IDs. 
It was built by Baobab Health Trust. 


##Requirements

* Ruby 2.5.0

* Rails 5.2.0

* MySQL 5.5

* CouchDB 1.6.1

##Dependancies

* DDE-Jobs Application: Used to sync data between Couchdb database and MySQL database.
                        The application can be cloned from git@bitbucket.org:baobabhealthtrust/dde-jobs.git
                        to authorized users.

##Setting Up

###DDE Master AND DDE Proxy

* Open your terminal

* Clone DDE Application from bitbucket.
  ```
    git clone git@bitbucket.org:baobabhealthtrust/dde3.git
  ```
  
* Enter into the root of your application by typing 
  ```
    cd dde3
  ```
  
* Copy all .yml.example files in config folder into .yml files.
  ```
    cp config/*.yml.example config/*.yml
  ```
  
* Configure your MySQL and CouchDB databases in config/database.yml and couchdb.yml files respectively.
  Provide username, password, database name, host and port (if necessary).

* Run
  ```
    bundle install
  ```

###Setting up DDE Master

1. Initialize database by typing the following in the command line 
   ```
     rake db:create db:migrate db:seed
   ```
   
2. Dump dde mysql database to a file in db folder. Name the sql file dde_metadata.sql
   ```
     $mysqldump -u root -p dde_database > db/dde_metadata.sql
   ```

3. Load MySQL national ids dump into DDE MySQL npids table.

4. You can now start DDE master server.
   ```
    passenger start -p <PORT_NUMBER>
   ```

###Setting up DDE Proxy

1. Copy you config files by Executing:

    cp config/database.yml.example config/database.yml
    cp config/couchdb.yml.example config/couchdb.yml
    cp config/master_couchdb.yml.example config/master_couchdb.yml
    cp config/application.yml.example config/application.yml
    cp config/secrets.yml.example config/secrets.yml

2. Configure the config file database.yml, couchdb.yml and master_couchdb.yml
   
    Provide all the required feilds.
    Please Note: All hosts in couchdb.yml and master_couchdb.yml should be their public IP addresses which are accessible outside their local network.

3. Load dde_metadata.sql into proxy dde mysql database
   ```
    $mysql -u root -p dde_proxy_database < db/dde_metadata.sql
   ```
   
4. Replicate DDE Master Couchdb to your local DDE Proxy Couchdb.

5. Configure Nginx to start the application
  
6. Setup DDE Data Sync cron job.

    * In your terminal, type:
      ```
      crontab -e

      */5 * * * * bash -l -c 'cd _PATH__TO__DDE_/bin && ./dde_database_updater.sh DDE_APP_RUNNING_ENVIRONMENT | ./timestamp.sh 1>> ../log/dde3_cron.log 2>> ../log/dde3_cron_error.log'
        ```
    Replace DDE_APP_RUNNING_ENVIRONMENT with the environment of dde3 application eg "development"

    This sets your cron job to run every 5 minutes.

    * Save the changes and close the cron tab.

7. Run the following command:
    ```
    sudo sed -i 's/#TMPTIME=0/TMPTIME=0/g' /etc/default/rcS

    ```





