#!/usr/bin/env ruby

# require "csv"
require "json"
require "logger"
require "rest-client"
require "mysql2"

require_relative "bantu_soundex"

mysql_config = YAML::load(File.open("#{Rails.root}/config/database.yml"))
es_config = YAML::load(File.open("#{Rails.root}/config/es.yml"))


JSON_CONTENT_TYPE = "application/json"

LOGGER = Logger.new STDOUT

MYSQL_HOST = mysql_config['development']['host']
MYSQL_DATABASE = mysql_config['development']['database']
MYSQL_USER = mysql_config['development']['username']
MYSQL_PASS = mysql_config['development']['password']
ES_PORT = es_config['development']['port']
ES_HOST = es_config['development']['host']
ES_PROTOCOL = es_config['development']['protocol']

BATCH_SIZE = 10_000

HOME_DISTRICT_ATTR_ID = 4
HOME_VILLAGE_ATTR_ID = 6
HOME_TRADITIONAL_AUTHORITY_ATTR_ID = 5

ES_BULK_API_URL = "#{ES_PROTOCOL}://#{ES_HOST}:#{ES_PORT}/people/_doc/_bulk"

CONN = Mysql2::Client.new host: MYSQL_HOST, database: MYSQL_DATABASE, username: MYSQL_USER, password: MYSQL_PASS

def load_people_into_es
  if File.exist?("#{Rails.root}/log/last_updated.log")
    last_updated = File.read("#{Rails.root}/log/last_updated.log")
  else
    file = File.open("#{Rails.root}/log/last_updated.log", "w")
    file.syswrite("1900-01-01")
    file.close
  end

  
  count = 0
  CONN.query("SELECT count(*) AS count FROM people where updated_at > '#{last_updated}'").each do |row|
    count += row["count"]
  end

  LOGGER.info "Loading #{count} people from MySQL to Elasticsearch"

  max_updated_at = Person.maximum('updated_at')

  offset = 0
  while offset < count
    LOGGER.info "Loading data from mysql:/#{MYSQL_DATABASE}/users in range [#{offset}, #{offset + BATCH_SIZE}]"
    people = []
    max_updated_at = Person.maximum('updated_at')

    sql_query = "SELECT person_id, couchdb_person_id AS id, given_name, family_name,
                        birthdate, birthdate_estimated, gender
                 FROM people 
                 WHERE updated_at > '#{last_updated}' 
                 ORDER BY person_id LIMIT #{offset}, #{BATCH_SIZE}"

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
  file = File.open("#{Rails.root}/log/last_updated.log", "w")
  file.syswrite("#{max_updated_at}")
  file.close
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
    person_exist = `curl #{ES_PROTOCOL}://#{ES_HOST}:#{ES_PORT}/_search -H "Content-Type: application/json" -d '{ "query": {"term": {"id": "#{person['id']}"}}}'`
    person_exist = JSON.parse(person_exist)
    
    if person_exist['hits']['total'].to_i >= 1
      person_exist['hits']['hits'].each do |record|
        `curl -X DELETE #{ES_PROTOCOL}://#{ES_HOST}:#{ES_PORT}/people/_doc/#{record['_id']}`
        puts "Deleted #{record['_id']}" 
      end
    end

    query << JSON.dump({index: {}})
    query << JSON.dump(person)
  end

  query.join("\n") + "\n"   # Bulk query must be terminated by a newline
end

load_people_into_es   