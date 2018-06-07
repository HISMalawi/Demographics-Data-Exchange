# README

DDE stands for Demographics Data Exchange. It was written in Ruby on Rails. Its main purpose is to manage patient IDs. 
It was built by Baobab Health Trust. 


###REQUIREMENTS


Below are some simple steps to follow when you want to setup DDE.

Requirements

Ruby 2.5.0

Rails 5.2.0

MySQL

CouchDB

###HOW TO SET IT UP


Open your terminal

Get a source code from github by typing "git clone git@bitbucket.org:baobabhealthtrust/dde3.git"

Enter into the root of your application by typing "cd dde3"

Type "cp config/database.yml.example config/database.yml"

Type "cp config/couchdb.yml.example config/couchdb.yml"

Note: Open config/database.yml and edit the file. Provide new mysql database name, username and password

Note: Open config/couchdb.yml and edit the file. Provide new couchdb database name, username and password.

Type "bundle install". 

Type "rake db:create db:migrate db:seed".

NB: Load national ids in npid table

After completing the above steps, you may now run the application by typing "passenger start"

Your application is now running on port 3000
===================================================================================================================
