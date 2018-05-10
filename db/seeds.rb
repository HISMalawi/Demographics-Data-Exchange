# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

require 'csv'

puts ""
puts ""
puts ""
puts "Defaault user and user roles ..."
sleep 3

#Create default user ...
couchdb_user  = CouchdbUser.create(username: 'admin', 
  email: 'admin@baobabhealth.org', password_digest: 'bht.dde3!')

user  = User.create(username: 'admin', couchdb_user_id: couchdb_user.id , 
                            email: couchdb_user.email, password: 'bht.dde3!')
couchdb_user.update_attributes(password_digest: user.password_digest)

roles = [
  ['Administrator','System admin'],
  ['EMR application','Eletronic medical record application']
]

(roles).each do |r, description|
  couchdb = CouchdbRole.create(role: r, description: description)
  Role.create(role: r, description: description, couchdb_role_id: couchdb.id)
  puts "Adding role: #{r} #{description} ...."
end

Role.where(role: 'Administrator').each do |role|
  couchdb = CouchdbUserRole.create(role_id: role.couchdb_role_id, user_id: couchdb_user.id)
  UserRole.create(couchdb_role_id: couchdb.id, 
    user_id: user.id, 
    couchdb_user_id: couchdb_user.id,
    role_id:  role.id)
  puts "Adding user role: #{role.role} ...."
end

puts ""
puts ""
puts ""
puts "Location Tags ..."
sleep 3

person_attributes = [
  'Current district','Current traditional authority','Current village', 
  'Home district','Home traditional authority','Home village', 
  'Nationality', 'Cell phone number','Work phone number','Home phone number',
  'Occupation','Landmark','Legacy identification','Nationality'
]

person_attributes.each do |pa|
  couchdb       = CouchdbPersonAttributeType.create(name: pa)
  activerecord  = PersonAttributeType.create(name: pa, couchdb_person_attribute_type_id: couchdb.id)
end


location_tag_hash = {}
CSV.foreach("#{Rails.root}/app/assets/data/health_facilities.csv", headers: true, encoding: 'ISO-8859-1') do |row|
  next if row[5].blank?
  next unless location_tag_hash[row[5].squish].blank?

  couchdb         = CouchdbLocationTag.create(name: row[5].squish) 
  activerecord    = LocationTag.create(couchdb_location_tag_id: couchdb.id, name: couchdb.name)
  location_tag_hash[couchdb.name]  = activerecord
  puts "Created location_tag: #{couchdb.name} ...."
end

location_tag_hash = {}
CSV.foreach("#{Rails.root}/app/assets/data/health_facilities.csv", headers: true, encoding: 'ISO-8859-1') do |row|
  next if row[6].blank?
  next unless location_tag_hash[row[6].squish].blank?

  couchdb         = CouchdbLocationTag.create(name: row[6].squish) 
  activerecord    = LocationTag.create(couchdb_location_tag_id: couchdb.id, name: couchdb.name)
  location_tag_hash[couchdb.name]  = activerecord
  puts "Created location_tag: #{couchdb.name} ...."
end

['System command center','District','Northern','Central East','Central West','South East','South West','Urban','Rural'].each do |name|
  couchdb         = CouchdbLocationTag.create(name: name) 
  activerecord    = LocationTag.create(couchdb_location_tag_id: couchdb.id, name: couchdb.name)
  puts "Created location_tag: #{couchdb.name} ...."
end

puts ""
puts ""
puts ""
puts "Creating Districts ..."
sleep 3


districts = []

CSV.foreach("#{Rails.root}/app/assets/data/health_facilities.csv", headers: true, encoding: 'ISO-8859-1') do |row|
  next if row[0].blank?
  districts << [row[0].squish, row[1]]
  districts = districts.uniq
end

location_tag = LocationTag.where(name: 'District').first
districts.each do |name, code|
  ActiveRecord::Base.transaction do
    couchdb_country = CouchdbLocation.create(name: name, code: code, creator: couchdb_user.id)
    couchdb_location_tag_map = CouchdbLocationTagMap.create(location_id: couchdb_country.id, 
			location_tag_id: location_tag.couchdb_location_tag_id)

    country = Location.create(name: name, code: code, creator: user.id, couchdb_location_id: couchdb_country.id)
    LocationTagMap.create(location_id: country.id, 
			location_tag_id: location_tag.id,
			couchdb_location_tag_id: couchdb_location_tag_map.id,
			couchdb_location_id:	couchdb_country.id)

    puts "########### #{code} ........... #{name}"
  end
end

puts ""
puts ""
puts ""
puts "Creating facilities (clinics) ..."
sleep 3

CSV.foreach("#{Rails.root}/app/assets/data/health_facilities.csv", headers: true, encoding: 'ISO-8859-1') do |row|
  next if row[3].blank?

  name            = row[3].squish
  facility_code   = row[2].squish rescue nil
  district_name   = row[0].squish
  zone            = row[4].squish
  facility_type   = row[5].squish
  mga             = row[6].squish
  geographic_area = row[7].squish
  latitude        = row[8].squish
  longitude       = row[9].squish

  ActiveRecord::Base.transaction do
    district  = Location.where(name: district_name).first

    couchdb_facility = CouchdbLocation.create(name: name, code: facility_code, 
      creator: couchdb_user.id, longitude: longitude, latitude: latitude, 
      parent_location:  district.couchdb_location_id)

    facility = Location.create(name: name, code: facility_code, 
      creator: user.id, longitude: longitude, latitude: latitude, 
      parent_location:  district.location_id, couchdb_location_id: couchdb_facility.id)

    [zone, facility_type, mga, geographic_area].each do |lt|
      lt_location_tag = LocationTag.where(name: lt).first
      c = CouchdbLocationTagMap.create(location_id: couchdb_facility.id, 
			  location_tag_id: lt_location_tag.couchdb_location_tag_id)

      LocationTagMap.create(location_id: facility.id, 
			  location_tag_id: lt_location_tag.id,
        couchdb_location_tag_id: c.location_tag_id,
        couchdb_location_id: c.location_id)
    end


    puts "########### #{facility_code} ........... #{name}"
  end

end

############################################
couchdb_bht = CouchdbLocation.create(name: 'Baobab Health Trust', 
  code: 'BHT', creator: couchdb_user.id)

activerecord_bht = Location.create(name: couchdb_bht.name, code: couchdb_bht.code, 
  couchdb_location_id: couchdb_bht.id, creator: user.id)

location_tag  = LocationTag.where(name: 'System command center').first
  c = CouchdbLocationTagMap.create(location_id: couchdb_bht.id, 
    location_tag_id: location_tag.couchdb_location_tag_id)

LocationTagMap.create(location_id: activerecord_bht.id, 
  location_tag_id: location_tag.id,
  couchdb_location_tag_id: c.location_tag_id,
  couchdb_location_id: couchdb_bht.id)


user.update_attributes(location_id: activerecord_bht.location_id)
couchdb_user.update_attributes(location_id: activerecord_bht.couchdb_location_id)





puts "Default user: >>>>"
puts "        username: admin"
puts "        password: bht.dde3!"
