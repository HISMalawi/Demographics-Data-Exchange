# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# require 'csv'

# puts ""
# puts ""
# puts ""
# puts "Default user and user roles ..."
# sleep 3

# #Create default user ...
# couchdb_user  = CouchdbUser.create(username: 'admin',
#   email: 'admin@baobabhealth.org', password_digest: 'bht.dde3!')

# user  = User.create(username: 'admin', couchdb_user_id: couchdb_user.id ,
#   email: couchdb_user.email, password: 'bht.dde3!')
# couchdb_user.update_attributes(password_digest: user.password_digest)

# roles = [
#   ['Administrator','System admin'],
#   ['EMR application','Eletronic medical record application']
# ]

# (roles).each do |r, description|
#   couchdb = CouchdbRole.create(role: r, description: description)
#   Role.create(role: r, description: description, couchdb_role_id: couchdb.id)
#   puts "Adding role: #{r} #{description} ...."
# end

# Role.where(role: 'Administrator').each do |role|
#   couchdb = CouchdbUserRole.create(role_id: role.couchdb_role_id, user_id: couchdb_user.id)
#   UserRole.create(couchdb_role_id: couchdb.id,
#     user_id: user.id,
#     couchdb_user_id: couchdb_user.id,
#     role_id:  role.id)
#   puts "Adding user role: #{role.role} ...."
# end

# puts ""
# puts ""
# puts ""
# puts "Location Tags ..."
# sleep 3

# person_attributes = [
#   'Current district','Current traditional authority','Current village',
#   'Home district','Home traditional authority','Home village',
#   'Nationality', 'Cell phone number','Work phone number','Home phone number',
#   'Occupation','Landmark','Legacy identification','National patient identifier',
#   'HTN number', 'ART number'
# ]

# person_attributes.each do |pa|
#   couchdb       = CouchdbPersonAttributeType.create(name: pa)
#   activerecord  = PersonAttributeType.create(name: pa, couchdb_person_attribute_type_id: couchdb.id)
# end


# location_tag_hash = {}
# CSV.foreach("#{Rails.root}/app/assets/data/health_facilities.csv", headers: true, encoding: 'ISO-8859-1') do |row|
#   next if row[5].blank?
#   next unless location_tag_hash[row[5].squish].blank?

#   couchdb         = CouchdbLocationTag.create(name: row[5].squish)
#   activerecord    = LocationTag.create(couchdb_location_tag_id: couchdb.id, name: couchdb.name)
#   location_tag_hash[couchdb.name]  = activerecord
#   puts "Created location_tag: #{couchdb.name} ...."
# end

# location_tag_hash = {}
# CSV.foreach("#{Rails.root}/app/assets/data/health_facilities.csv", headers: true, encoding: 'ISO-8859-1') do |row|
#   next if row[6].blank?
#   next unless location_tag_hash[row[6].squish].blank?

#   couchdb         = CouchdbLocationTag.create(name: row[6].squish)
#   activerecord    = LocationTag.create(couchdb_location_tag_id: couchdb.id, name: couchdb.name)
#   location_tag_hash[couchdb.name]  = activerecord
#   puts "Created location_tag: #{couchdb.name} ...."
# end

# ['System command center','District','Northern','Central East','Central West','South East','South West','Urban','Rural'].each do |name|
#   couchdb         = CouchdbLocationTag.create(name: name)
#   activerecord    = LocationTag.create(couchdb_location_tag_id: couchdb.id, name: couchdb.name)
#   puts "Created location_tag: #{couchdb.name} ...."
# end

# puts ""
# puts ""
# puts ""
# puts "Creating Regions ..."
# sleep 3

# [['South','Southern Region'],['Centre','Central Region'],['North','Northern Region']].each do |name, desc|
#   r = Region.create(name: name, description: desc, creator: user.id)
#   puts "Created region: #{r.name} ...."

# end

# puts ""
# puts ""
# puts ""
# puts "Creating Districts ..."
# sleep 3

# districts = []

# CSV.foreach("#{Rails.root}/app/assets/data/health_facilities.csv", headers: true, encoding: 'ISO-8859-1') do |row|
#   next if row[0].blank?
#   districts << [row[0].squish, row[1], row[4]]
#   districts = districts.uniq
# end

# location_tag = LocationTag.where(name: 'District').first
# districts.each do |name, code, zone|
#   ActiveRecord::Base.transaction do
#     couchdb_country = CouchdbLocation.create(name: name, code: code, creator: couchdb_user.id)
#     couchdb_location_tag_map = CouchdbLocationTagMap.create(location_id: couchdb_country.id,
# 			location_tag_id: location_tag.couchdb_location_tag_id)

#     country = Location.create(name: name, code: code, creator: user.id, couchdb_location_id: couchdb_country.id)
#     LocationTagMap.create(location_id: country.id,
# 			location_tag_id: location_tag.id,
# 			couchdb_location_tag_id: couchdb_location_tag_map.id,
#       couchdb_location_id:	couchdb_country.id)

#     if (zone.downcase.match(/north/))
#       # add to northern region
#       region = Region.where(name: "North").first
#       RegionDistrict.create(region_id: region.id, district_id: country.id)

#     elsif (zone.downcase.match(/central/))
#       # add to central region
#       region = Region.where(name: "Centre").first
#       RegionDistrict.create(region_id: region.id, district_id: country.id)

#     elsif (zone.downcase.match(/south/))
#       # add to southern region
#       region = Region.where(name: "South").first
#       RegionDistrict.create(region_id: region.id, district_id: country.id)

#     end

#     puts "########### #{code} ........... #{name}................. #{zone}"
#   end
# end

# puts ""
# puts ""
# puts ""
# puts "Creating facilities (clinics) ..."
# sleep 3

# CSV.foreach("#{Rails.root}/app/assets/data/health_facilities.csv", headers: true, encoding: 'ISO-8859-1') do |row|
#   next if row[3].blank?

#   name            = row[3].squish
#   facility_code   = row[2].squish rescue nil
#   district_name   = row[0].squish
#   zone            = row[4].squish
#   facility_type   = row[5].squish
#   mga             = row[6].squish
#   geographic_area = row[7].squish
#   latitude        = row[8].squish
#   longitude       = row[9].squish

#   ActiveRecord::Base.transaction do
#     district  = Location.where(name: district_name).first

#     couchdb_facility = CouchdbLocation.create(name: name, code: facility_code,
#       creator: couchdb_user.id, longitude: longitude, latitude: latitude,
#       parent_location:  district.couchdb_location_id)

#     facility = Location.create(name: name, code: facility_code,
#       creator: user.id, longitude: longitude, latitude: latitude,
#       parent_location:  district.location_id, couchdb_location_id: couchdb_facility.id)

#     [zone, facility_type, mga, geographic_area].each do |lt|
#       lt_location_tag = LocationTag.where(name: lt).first
#       c = CouchdbLocationTagMap.create(location_id: couchdb_facility.id,
# 			  location_tag_id: lt_location_tag.couchdb_location_tag_id)

#       LocationTagMap.create(location_id: facility.id,
# 			  location_tag_id: lt_location_tag.id,
#         couchdb_location_tag_id: c.location_tag_id,
#         couchdb_location_id: c.location_id)
#     end

#     DistrictSite.create(district_id: district.location_id, site_id: facility.id)


#     puts "########### (#{facility.id}) #{facility_code} ........... #{name}....."
#   end

# end

# ############################################
# couchdb_bht = CouchdbLocation.create(name: 'Baobab Health Trust',
#   code: 'BHT', creator: couchdb_user.id)

# activerecord_bht = Location.create(name: couchdb_bht.name, code: couchdb_bht.code,
#   couchdb_location_id: couchdb_bht.id, creator: user.id)

# location_tag  = LocationTag.where(name: 'System command center').first
# c = CouchdbLocationTagMap.create(location_id: couchdb_bht.id,
#   location_tag_id: location_tag.couchdb_location_tag_id)

# LocationTagMap.create(location_id: activerecord_bht.id,
#   location_tag_id: location_tag.id,
#   couchdb_location_tag_id: c.location_tag_id,
#   couchdb_location_id: couchdb_bht.id)


# user.update_attributes(location_id: activerecord_bht.location_id,
#     couchdb_location_id: couchdb_bht.id
# )
# couchdb_user.update_attributes(location_id: activerecord_bht.couchdb_location_id)

# couchdb_yml = Rails.root.to_s + "/config/couchdb.yml"
# env = Rails.env
# couch_db_settings = YAML.load_file(couchdb_yml)[env]

# couch_host = couch_db_settings["host"]
# couch_prefix = couch_db_settings["prefix"]
# couch_suffix = couch_db_settings["suffix"]
# couch_db = couch_prefix.to_s + "_" + couch_suffix
# couch_port = couch_db_settings["port"]
# file_path = Rails.root.to_s + "/log/last_sequence.txt"

# couch_address = "http://#{couch_host}:#{couch_port}/#{couch_db}/_changes?include_docs=true"

# received_params = RestClient.get(couch_address)
# results = JSON.parse(received_params)
# last_sequence_number = results["last_seq"]
# puts "Updated sequence #: #{last_sequence_number}"
# #CouchChanges.update_sequence_in_file(last_sequence_number)

# puts "Default user: >>>>"
# puts "        username: admin"
# puts "        password: bht.dde3!"

#Update to DDE 4
Config.create!(config: 'host',
               config_value: '10.44.0.48',
               description: 'DDE Master IP/Path',
               uuid: '94f07d78-9dca-11eb-a899-dc41a91e235e') unless Config.find_by_config('host')

Config.create!(config: 'peer_port',
               config_value: '8000',
               description: 'DDE Master Port',
               uuid: 'a0f576e9-9dca-11eb-a899-dc41a91e235e') unless Config.find_by_config('peer_port')


Config.create!(config: 'push_seq',
               config_value: 0,
               description: 'push vector clock',
               uuid: 'ba45bb9c-9dca-11eb-a899-dc41a91e235e') unless Config.find_by_config('push_seq')

Config.create!(config: 'pull_seq',
               config_value: 0,
               description: 'pull vector clock',
               uuid: 'c22d75c6-9dca-11eb-a899-dc41a91e235e') unless Config.find_by_config('pull_seq')

Config.create!(config: 'sync_pwd',
               config_value: 'dde_sync_password',
               description: 'Password for syncing user',
               uuid: 'b32599a5-a072-11eb-a899-dc41a91e235e') unless Config.find_by_config('sync_pwd')


Config.create!(config: 'sync_user',
               config_value: 'dde_sync_user',
               description: 'User for syncing',
               uuid: 'b5c0ecd1-a072-11eb-a899-dc41a91e235e') unless Config.find_by_config('sync_user')

Config.create!(config: 'npid_seq',
               config_value: 0,
               description: 'NPID pull vector clock',
               uuid: 'ebc28cab-b7d8-11eb-8cf6-dc41a91e235e') unless Config.find_by_config('npid_seq')
