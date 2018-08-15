require "logger"
require "json"
require "rest-client"

# A basic client for accessing Elasticsearch.
#
# Client basically abstracts away json serialization and deserialization.
class ElasticsearchClient
  # ASIDE: Cant we make this class a singleton? What are the advantages of
  # doing so?

  # Instantiate ElasticSearchClient
  #
  # @param host Name of host Elasticsearch is running on (default: localhost)
  # @param port Port Elasticsearch is running on (default: 9200)
  def initialize(host: "localhost", port: 9200, rest_client: nil)
    @base_url = "http://#{host}:#{port}"
    @rest_client = (rest_client or RestClient)
  end

  def get(path)
    exec_request path do |expanded_path|
      LOGGER.debug("GETting from Elasticsearch[#{expanded_path}]")
      @rest_client.get(expanded_path)
    end
  end

  def post(path, data)
    exec_request path do |expanded_path|
      json_dump = JSON.dump(data)
      LOGGER.debug("POSTing data to Elasticsearch[#{expanded_path}]: #{json_dump}")
      @rest_client.post(expanded_path, json_dump, content_type: JSON_CONTENT_TYPE)
    end
  end

  def put(path, data)
    exec_request path do |expanded_path|
      json_dump = JSON.dump(data)
      LOGGER.debug("PUTting data to Elasticsearch[#{expanded_path}]: #{json_dump}")
      @rest_client.put(expanded_path, json_dump, content_type: JSON_CONTENT_TYPE)
    end
  end

  def delete(path)
    exec_request path do |expanded_path|
      LOGGER.debug("DELETE-ing from Elasticsearch[#{expanded_path}]")
      @rest_client.delete(expanded_path)
    end
  end

  def to_s
    "Elasticsearch[#{@base_url}]"
  end

  private

  JSON_CONTENT_TYPE = "application/json"
  LOGGER = Logger.new STDOUT

  def exec_request(path)
    response = yield expand_path(path)

    code = response.code
    content_type = response.headers[:content_type]

    LOGGER.info "Got response from Elasticsearch\n\tCode: #{code}\n\tBody: #{response}"

    unless (200..300).include?(code) and content_type.include? JSON_CONTENT_TYPE
      LOGGER.error("Elasticsearch responded: #{code} - #{content_type}\n\t#{response.body}")
      raise StandardError, "Invalid response from Elasticsearch"
    end

    response.headers[:content_length].to_i > 0 ? JSON.parse(response.body) : nil
  end

  def expand_path(path)
    path = path.gsub /^\/+/, ""
    return "#{@base_url}/#{path}"
  end
end
