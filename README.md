# README

DDE stands for Demographics Data Exchange. It was written in Ruby on Rails. Its main purpose is to manage patient IDs. 
It was built by Baobab Health Trust. 


###REQUIREMENTS

Ruby 2.5.0

Rails 5.2.0

MySQL

CouchDB

###HOW TO SET IT UP


Open your terminal

Get a source code from bitbucket by typing **git clone git@bitbucket.org:baobabhealthtrust/dde3.git**

Enter into the root of your application by typing **cd dde3**

Type **cp config/database.yml.example config/database.yml**

Type **cp config/couchdb.yml.example config/couchdb.yml**

Type **cp config/secrets.yml.example config/secrets.yml**

Note: Open *config/database.yml* and edit the file. Provide new mysql database name, username and password

Note: Open *config/couchdb.yml* and edit the file. Provide new couchdb database name, username and password.

Type **bundle install**

Type **rake db:create db:migrate db:seed**

NB: Load mySQL national ids dump into mySQL npid table

Type **passenger start -p <PORT_NUMBER>**


## dde-jobs application is for syncing data
Get a source code from bitbucket by typing **git clone git@bitbucket.org:baobabhealthtrust/dde-jobs.git**

Enter into the root of your application by typing **cd dde-jobs**

Get config/database.yml, config/couchdb.yml from dde application and put it in config directory of dde-jobs application

Type **cp config/secrets.yml.example config/secrets.yml**

Type **bundle install**

Type **passenger start -p <PORT_NUMBER>**

