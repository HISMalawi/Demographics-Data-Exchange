# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

#Create default user ...
couchdb_user  = CouchdbUser.create(email: 'admin@baobabhealth.org', password_digest: 'bht.dde3!')
user          = User.create(couchdb_user_id: couchdb_user.id , email: couchdb_user.email, password: 'bht.dde3!')
couchdb_user.update_attributes(password_digest: user.password_digest)

roles = [
  ['Administrator','System admin'],
  ['EMR application','Eletronic medical record application']
]

(roles).each do |r, description|
  couchdb = CouchdbRole.create(role: r, description: description)
  Role.create(role: r, description: description, couchdb_role_id: couchdb.id)
  puts "Adding role: #{r} #{description}"
end

Role.where(role: 'Administrator').each do |role|
  couchdb = CouchdbUserRole.create(role_id: role.couchdb_role_id, user_id: couchdb_user.id)
  UserRole.create(couchdb_role_id: couchdb.id, 
    user_id: user.id, 
    couchdb_user_id: couchdb_user.id,
    role_id:  role.id)
  puts "Adding user role: #{role.role}"
end
