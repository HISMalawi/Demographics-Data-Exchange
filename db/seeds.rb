# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

#Create default user ...
couchdb = CouchdbUser.create(email: 'admin@baobabhealth.org', password_digest: 'bht.dde3!')
user    = User.create(couchdb_user_id: couchdb.id , email: couchdb.email, password_digest: 'bht.dde3!')
couchdb.update_attributes(password_digest: user.password_digest)



