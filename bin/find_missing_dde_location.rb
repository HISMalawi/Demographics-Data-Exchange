# sync_locations_generate_sql.rb
require 'active_record'
require 'mysql2'
require 'io/console'

# --- Prompt for DB credentials ---
print "Enter DDE4 database name (default: dde4_master): "
dde_db = STDIN.gets.strip
dde_db = "dde4_master" if dde_db.empty?

print "Enter OpenMRS database name (default: openmrs_dev): "
openmrs_db = STDIN.gets.strip
openmrs_db = "openmrs_dev" if openmrs_db.empty?

print "Enter MySQL username (default: root): "
db_user = STDIN.gets.strip
db_user = "root" if db_user.empty?

print "Enter MySQL password: "
db_pass = STDIN.noecho(&:gets).strip
puts "" # new line after password input

print "Enter DB host (default: localhost): "
db_host = STDIN.gets.strip
db_host = "localhost" if db_host.empty?

# --- DB Connections ---
class DDEDatabase < ActiveRecord::Base
  self.abstract_class = true
end

class OpenmrsDatabase < ActiveRecord::Base
  self.abstract_class = true
end

DDEDatabase.establish_connection(
  adapter:  'mysql2',
  host:     db_host,
  username: db_user,
  password: db_pass,
  database: dde_db
)

OpenmrsDatabase.establish_connection(
  adapter:  'mysql2',
  host:     db_host,
  username: db_user,
  password: db_pass,
  database: openmrs_db
)

# --- Models ---
class DDELocation < DDEDatabase
  self.table_name = "locations"
end

class District < DDEDatabase
  self.table_name = "districts"
end

class OpenmrsLocation < OpenmrsDatabase
  self.table_name = "location"
end

# --- City-village mapping ---
def map_city_village(name)
  return "" if name.nil?
  cleaned = name.to_s.strip.downcase
  return "Nkhotakota" if cleaned == "nkhota-kota"
  return "Mzimba" if cleaned.include?("mzimba") || cleaned.include?("mzuzu")
  return "Nkhata-bay" if cleaned.include?("nkhata")
  name.strip
end

# --- Output file ---
output_file = "db/meta_data/missing_locations.sql"
FileUtils.mkdir_p(File.dirname(output_file))

File.open(output_file, "w") do |f|
  OpenmrsLocation.find_each do |openmrs_location|
    mapped_city = map_city_village(openmrs_location.city_village)

    district = District.find_by("LOWER(name) = ?", mapped_city.downcase)

    unless district
      puts "⚠️ Skipping openmrs location #{openmrs_location.location_id} - district '#{mapped_city}' not found"
      next
    end

    # Check if location exists
    dde_location = DDELocation.find_by(location_id: openmrs_location.location_id)
    next if dde_location # Skip existing locations

    # Generate INSERT SQL
    insert_sql = <<-SQL
      INSERT INTO locations (location_id, name, district_id, creator, created_at, updated_at)
      VALUES (#{openmrs_location.location_id}, #{DDEDatabase.connection.quote(openmrs_location.name)}, #{district.district_id}, 1, NOW(), NOW());
    SQL

    f.puts insert_sql
    puts "➕ Added SQL for missing Location ##{openmrs_location.location_id}"
  end
end

puts "✅ SQL dump generated at #{output_file}"