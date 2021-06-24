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

###DDE Master AND DDE Proxy

* Open your terminal

* Clone DDE Application from bitbucket.
  ```
    https://github.com/HISMalawi/Demographics-Data-Exchange.git dde4
  ```
  
* Enter into the root of your application by typing 
  ```
    cd dde4
  ```
  
* Copy all .yml.example files in config folder into .yml files.
  ```
    cp config/*.yml.example config/*.yml
  ```
  
* Configure your MySQL database in config/database.yml file respectively.
  Provide username, password, database name, host and port (if necessary).

* Run
  ```
    bundle install
  ```

  * Run
  ```
    rails db:migrate db:seed
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
    cp config/secrets.yml.example config/secrets.yml

2. Configure the config file database.yml
   
    Provide all the required feilds.
    Please Note: All hosts in should be their public IP addresses which are accessible outside their local network.

3. Load dde_metadata.sql into proxy dde mysql database
   ```
    $mysql -u root -p dde_proxy_database < db/dde_metadata.sql
   ```
   
5. Configure Nginx to start the application
  
7. Run the following command:
    ```
    sudo sed -i 's/#TMPTIME=0/TMPTIME=0/g' /etc/default/rcS

    ```





