require "logger"
require "rest-client"

require_relative "elasticsearch_client"

# A Person Data Access Object that uses Elasticsearch as its store.
class ElasticsearchPersonDAO

  # Instantiate ElasticSearchPersonDAO
  #
  # @param esclient An ElasticsearchClient for accessing Elasticsearch
  #
  # @note If called without arguments a default ElasticsearchClient is used.
  # @see ElasticsearchClient
  def initialize(elasticsearch_client = nil)
    @elasticsearch_client = (elasticsearch_client or ElasticsearchClient.new)
  end

  def save(person)
    LOGGER.debug "Saving to Elasticsearch person: #{person}"
    @elasticsearch_client.put(expand_path(person["id"]), person)["_id"]
  end

  def get(id)
    LOGGER.debug "Fetching from Elasticsearch person ##{id}"
    @elasticsearch_client.get(expand_path(id))["_source"]   # No ketchup just the source
  end

  def search(data)
    LOGGER.debug "Searching in Elasticsearch for people matching: #{data}"
    query = {
      "query" => {
        "bool" => {
          "should" => data.collect { |f, v| {match: {f => v}} },
          "minimum_should_match" => (MINIMUM_SHOULD_MATCH_PERCENTAGE * data.size).round,
        },
      },
    }
    hits = @elasticsearch_client.post(expand_path("_search"), query)["hits"]["hits"]
    # Our users need not know of our guts - let's give them their people
    hits.collect { |hit| hit["_source"] }
  end

  # ASIDE: The two methods below ought to be in some other class. You know separation
  # of concerns, management of an index vs use of that index. This extremely lowers
  # this class' cohesiveness. Was just lazy to fix...

  # Create person index on Elasticsearch
  def create_index
    LOGGER.info "Creating person index at #{@elasticsearch_client}"
    response = @elasticsearch_client.put("people", {
      "mappings" => {
        "_doc" => {
          "properties" => {
            "id" => {"type" => "text"},   # We using couch doc_id which comes as a string.
            "family_name" => {"type" => "text"},
            "family_name_soundex" => {"type" => "text"},
            "given_name" => {"type" => "text"},
            "given_name_soundex" => {"type" => "text"},
            "birth_date" => {"type" => "date"},
            "gender" => {"type" => "text"},
            "home_district" => {"type" => "text"},
            "home_district_soundex" => {"type" => "text"},
            "home_village" => {"type" => "text"},
            "home_village_soundex" => {"type" => "text"},
            "home_traditional_authority" => {"type" => "text"},
            "home_traditional_authority_soundex" => {"type" => "text"},
          },
        },
      },
    })

    unless response and response["acknowledged"]
      raise StandardError, "Failed to create index: #{response}"
    end

    LOGGER.info "Index person created at #{@elasticsearch_client}"
  end

  # Delete person index on Elasticsearch
  def delete_index
    LOGGER.info "Deleting person index at #{@elasticsearch_client}..."
    response = @elasticsearch_client.delete "people"

    unless response and response["acknowledged"]
      raise StandardError, "Failed to delete index: #{response}"
    end

    LOGGER.info "Index person deleted at #{@elasticsearch_client}"
  end

  private

  LOGGER = Logger.new STDOUT

  MINIMUM_SHOULD_MATCH_PERCENTAGE = 0.8

  # Prepends index and document type to path
  def expand_path(path)
    "people/_doc/#{path}"
  end
end
