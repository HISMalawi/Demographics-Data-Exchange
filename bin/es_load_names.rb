#!/usr/bin/env ruby

# require "csv"
require "json"
require "logger"
require "rest-client"
require "mysql2"

require_relative "bantu_soundex"

JSON_CONTENT_TYPE = "application/json"

LOGGER = Logger.new STDOUT

MYSQL_HOST = "localhost"
MYSQL_DATABASE = "dde3_test_master"
MYSQL_USER = "root"
MYSQL_PASS = "pach321"

BATCH_SIZE = 5

HOME_DISTRICT_ATTR_ID = 4
HOME_VILLAGE_ATTR_ID = 6
HOME_TRADITIONAL_AUTHORITY_ATTR_ID = 5

ES_BULK_API_URL = "http://localhost:9200/people/_doc/_bulk"

CONN = Mysql2::Client.new host: MYSQL_HOST, database: MYSQL_DATABASE, username: MYSQL_USER, password: MYSQL_PASS

def load_people_into_es
  count = 0
  CONN.query("SELECT count(*) AS count FROM people").each do |row|
    count += row["count"]
  end

  LOGGER.info "Loading #{count} people from MySQL to Elasticsearch"

  offset = 0
  while offset < count
    LOGGER.info "Loading data from mysql:/#{MYSQL_DATABASE}/users in range [#{offset}, #{offset + BATCH_SIZE}]"
    people = []

    sql_query = "SELECT person_id, couchdb_person_id AS id, given_name, family_name,
                        birthdate, birthdate_estimated, gender
                 FROM people ORDER BY person_id LIMIT #{offset}, #{BATCH_SIZE}"

    CONN.query(sql_query).each do |person|
      puts person
      load_person_attributes!(person)
      load_person_soundex_fields!(person)
      people << person
    end

    es_query = make_es_bulk_query people

    begin
      LOGGER.debug "Pushing data to Elasticsearch[#{ES_BULK_API_URL}] using:\n#{es_query}"
      response = RestClient.post(ES_BULK_API_URL, es_query, content_type: JSON_CONTENT_TYPE)
      LOGGER.debug "Pushed data to Elasticsearch, got Elasticsearch response: #{response}"
    rescue => e
      LOGGER.error e.response
      raise e
    end

    offset += BATCH_SIZE
  end
end

def load_person_attributes!(person)
  query = <<END
  SELECT hd.value home_district, hv.value home_village, hta.value home_traditional_authority
  FROM person_attributes pa
    LEFT JOIN person_attributes hd on pa.person_id = hd.person_id
      AND hd.person_attribute_type_id = #{HOME_DISTRICT_ATTR_ID}
      AND hd.voided = 0
    LEFT JOIN person_attributes hv on pa.person_id = hv.person_id
      AND hv.person_attribute_type_id = #{HOME_VILLAGE_ATTR_ID}
      AND hv.voided = 0
    LEFT JOIN person_attributes hta on pa.person_id = hta.person_id
      AND hta.person_attribute_type_id = #{HOME_TRADITIONAL_AUTHORITY_ATTR_ID}
      AND hta.voided = 0
  WHERE pa.person_id = #{person["person_id"]}
  group by pa.person_id
END

  CONN.query(query).each do |attributes|
    person.merge!(attributes)
  end
end

def load_person_soundex_fields!(person)
  ["given_name", "family_name", "home_district", "home_village", "home_traditional_authority"].each do |field|
    if person[field].nil?
      # LOGGER.warn "Person ##{person["id"]} missing attribute #{field}"
      person["#{field}_soundex"] = nil
      next
    end

    person["#{field}_soundex"] = person[field].soundex
  end
end

def make_es_bulk_query(people)
  query = []

  people.each do |person|
    query << JSON.dump({index: {}})
    query << JSON.dump(person)
  end

  query.join("\n") + "\n"   # Bulk query must be terminated by a newline
end

load_people_into_es   # Start process

# ATTR_ID_NAME_MAP = {
#   4 => :home_district,
#   5 => :home_village,
#   6 => :home_traditional_authority,
# }
#
# PERSON_ID = 0
# PERSON_GIVEN_NAME = 1
# PERSON_FAMILY_NAME = 2
# PERSON_GENDER = 3
# PERSON_BIRTH_DATE = 4

# ATTR_PERSON_ID = 0
# ATTR_TYPE_ID = 1
# ATTR_VALUE = 2

# people = {}
# CSV.foreach("people.csv") do |row|
#   id = (row[PERSON_ID].gsub /\s+/, "").to_i
#   people[id] = {
#     id: id,
#     given_name: row[PERSON_GIVEN_NAME],
#     given_name_soundex: row[PERSON_GIVEN_NAME].soundex,
#     family_name: row[PERSON_FAMILY_NAME],
#     family_name_soundex: row[PERSON_FAMILY_NAME].soundex,
#     birth_date: row[PERSON_BIRTH_DATE],
#     gender: row[PERSON_GENDER],
#   }
#   print "Loaded person: #{people[id]}\n"
# rescue StandardError => e
#   print "Error: #{e.message}\n"
#   next
# end

# CSV.foreach("person_attributes.csv") do |row|
#   person_id = row[ATTR_PERSON_ID].gsub(/\s+/, "").to_i
#   print "Searching for person with id: #{person_id}\n"
#   person = people[person_id]
#   next unless person
#   attr_name = ATTR_ID_NAME_MAP[row[ATTR_TYPE_ID].to_i]
#   next unless attr_name
#   person[attr_name] = row[ATTR_VALUE]
#   person["#{attr_name}_soundex"] = row[ATTR_VALUE].soundex
#   print "Loaded person attribute: #{attr_name} - #{person}\n"
# rescue StandardError => e
#   print "Error: #{e.message}\n"
#   next
# end

# loaded = 0
# people.values.each do |person|
#   print "Pushing person to Elasticsearch: #{person}\n"
#   next unless person[:home_district] or person[:home_village] or person[:home_traditional_authority]
#   dump = JSON.dump(person)
#   response = RestClient.put("localhost:9200/people/_doc/#{person[:id]}", dump,
#                             content_type: JSON_CONTENT_TYPE)
#   puts response.body
#   loaded += 1
# rescue RestClient::ExceptionWithResponse => e
#   puts e.response
#   exit 255
# end

# print "Pushed #{loaded} people to elasticsearch\n"

# begin
#   mapping = {
#     mappings: {
#       _doc: {
#         properties: {
#           given_name: {type: :text},
#           given_name_soundex: {type: :text},
#           family_name: {type: :text},
#           family_name_soundex: {type: :text}
#         },
#       },
#     },
#   }

#   RestClient.delete("localhost:9200/people")

#   RestClient.put("localhost:9200/people", JSON.dump(mapping),
#                  content_type: JSON_CONTENT_TYPE)
# rescue RestClient::ExceptionWithResponse => e
#   puts e.response
#   exit 255
# end

# mysql_client = Mysql2::Client.new(
#   host: "localhost", username: "baobab", password: "baobab",
#   database: "people_names"
# )
# results = mysql_client.query("SELECT * FROM name_directory").each;

# results.each do |row|
#   given_name = row["name"]
#   given_name_soundex = row["soundex"]

#   family_name_row = results[Random.rand(family_names.size - 1)]
#   family_name = family_name_row["name"]
#   family_name_soundex = family_name_row["soundex"]

#   district, village, trad_auth = villages[Random.rand(villages.size - 1)]

#   person = {
#     given_name: given_name,
#     given_name_soundex: given_name.soundex,
#     family_name: family_name,
#     family_name_soundex: family_name.soundex,
#     birth_date: "2000/01/01",
#     home_district: district,
#     home_district_soundex: district.soundex,
#     home_village: village,
#     home_village_soundex: village.soundex,
#     home_traditional_authority: trad_auth,
#     home_traditional_authority_soundex: trad_auth.soundex
#   }

#   (1...5).each do
#     RestClient.post("localhost:9200/people/_doc", JSON.dump(person),
#                     content_type: JSON_CONTENT_TYPE)
#   end
#   puts "Loaded #{family_name}, #{given_name}"
# rescue RestClient::ExceptionWithResponse => e
#   puts e.response
#   exit 255
# end
