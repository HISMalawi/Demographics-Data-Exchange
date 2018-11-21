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

* MySQL 5.5 or higher

* CouchDB 1.6.1 or higher

* Elasticsearch 6.3.0 or higher

##Dependancies

* DDE-Jobs Application: Used to sync data between Couchdb database and MySQL database.
                        The application can be cloned from git@bitbucket.org:baobabhealthtrust/dde-jobs.git
                        to authorized users.

##Setting Up

###DDE Master AND DDE Proxy

* Open your terminal

* Clone DDE Application from bitbucket.
  ```
    $ git clone https://github.com/baobabhealthtrust/Demographics-Data-Exchange
  ```
  
* Enter into the root of your application by typing 
  ```
    $ cd Demographic-Data-Exchange
  ```
  
* Copy all .yml.example files in config folder into .yml files.
  ```
    $ cp config/database.yml.example config/database.yml
    $ cp config/couchdb.yml.example config/couchdb.yml
    $ cp config/master_couchdb.yml.example config/master_couchdb.yml
  ```
  
* Configure your MySQL and CouchDB databases in config/database.yml and couchdb.yml files respectively.
  Provide username, password, database name, host and port (if necessary).

* Configure couchdb for dde master couchdb in config/master_couchdb.yml

* Install rubygems by running the following command:
  ```
    $ bundle install
  ```

###Setting up DDE Master

1. Initialize database by typing the following in the command line 
   ```
    $ rails db:create db:migrate db:seed
   ```
   
2. Dump dde mysql database to a file in db folder. Name the sql file dde_metadata.sql
   ```
    $ mysqldump -u root -p dde_database > db/dde_metadata.sql
   ```

3. Load MySQL national ids dump into DDE MySQL npids table.

4. You can now start DDE master server.
   ```
    $ passenger start -p <PORT_NUMBER>
   ```

###Setting up DDE Proxy

1. Load dde_metadata.sql into proxy dde mysql database
   ```
    $ mysql -u root -p dde_proxy_database < db/dde_metadata.sql
   ```
   
2. Replicate DDE Master Couchdb to your local DDE Proxy Couchdb.

4. Start DDE Proxy Server
   ```
    $ passenger start -p <PORT_NUMBER>
  ```
  




