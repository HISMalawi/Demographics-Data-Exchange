#!/usr/bin/env ruby

# Initialises a people index in the configured Elasticsearch server for
# the people matching service.

require "logger"

require_relative "../lib/people_matching_service/elasticsearch_person_dao"

LOGGER = Logger.new STDOUT

USAGE = "USAGE:\n\tes_people_index create_index\n\tes_people_delete_index"

# Initialise person index
def create_es_index(es_person_dao)
  es_person_dao.create_index
end

# Delete person index
def delete_es_index(es_person_dao)
  LOGGER.info "Are you sure you want to delete the person index: [no]"

  input = STDIN.gets.strip
  unless input.downcase.match /y(es)?/
    LOGGER.info "Index not deleted."
    return 0
  end

  es_person_dao.delete_index
end

def main
  if ARGV.size == 0
    LOGGER.error "Invalid command\n#{USAGE}"
    exit 255
  end

  es_person_dao = ElasticsearchPersonDAO.new

  ARGV.each do |arg|
    case arg
    when "create_index"
      create_es_index es_person_dao
    when "delete_index"
      delete_es_index es_person_dao
    else
      LOGGER.error "Invalid argument: #{arg}"
    end
  end
end

main
