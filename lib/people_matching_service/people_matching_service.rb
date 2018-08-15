require "logger"
require "rest-client"
require "whitesimilarity"

require_relative "bantu_soundex"
require_relative "elasticsearch_person_dao"
require_relative "hash_matcher"

# A service class for finding duplicate people in any data store
#
# @example Find people matching some name
#   >> matching_service = PeopleMatchingService.new   # Uses elastic search at localhost:9200
#   >> matches = matching_service.find_duplicates({
#   >>    given_name: "Foobar",
#   >>    family_name: "Random"
#   >> })
#
# @example Find people using a custom Elasticsearch instance
#   >> require "elasticsearch_client"
#   >> require "elasticsearch_person_dao"
#   >> es_client = ElasticsearchClient(host: "some_host", port: "some_port",
#   >>                                 index: "some_index", doc_type: "some_doc_type")
#   >> es_person_dao = ElasticsearchPersonDAO esclient
#   >> matching_service = PeopleMatchingService.new person_dao: es_person_dao
#   >> matches = matching_service.match({given_name_soundex: "some_soundex_value"})
class PeopleMatchingService

  # Instantiate PeopleMatchingService
  #
  # @param people_dao A person data access object (default: ElasticsearchPersonDAO)
  def initialize(people_dao = nil)
    @people_dao = (people_dao or ElasticsearchPersonDAO.new)
  end

  # Find possible duplicates to `benchmark` in bound data store.
  #
  # @param benchmark A hash containing at least one of the following fields:
  #     - :given_name
  #     - :family_name
  #     - :gender
  #     - :birth_date
  #     - :home_district
  #     - :home_traditional_authority
  #     - :home_village
  # @param threshold Minimum similarity score between search_data and person to consider them duplicates
  # @param use_soundex Search for matches using soundex and not the *actual* values
  #
  # @returns A list of possible duplicates ([..., {score: float, person: PersonDTO}, ...])
  #
  # @see DDEPersonTransformer
  def find_duplicates(benchmark, threshold: MINIMUM_SIMILARITY_SCORE, use_soundex: false)
    #
    search_data = FIELDS_TO_MATCH.inject({}) do |search_data, field|
      value = benchmark[field]

      next search_data unless value

      if use_soundex and SOUNDEX_FIELDS.include? field
        soundex_field = "#{field}_soundex"
        search_data[soundex_field] = value.soundex
      else
        search_data[field] = value
      end

      search_data
    end

    LOGGER.debug "Converted benchmark to search_data: #{benchmark} <=> #{search_data}"

    matches = []
    matcher = HashMatcher.new benchmark, include: FIELDS_TO_MATCH, field_specs: FIELD_SPECS

    # Get people whose match score exceeds threshold
    @people_dao.search(search_data).each do |person|
      score = matcher.match(person)   # Compare this person to the benchmark
      if score < threshold
        LOGGER.debug "Dropped person due to low score:" \
                     "\n\tscore: #{score}" \
                     "\n\tperson: #{person}" \
                     "\n\tbenchmark: #{benchmark}"
        next
      end
      matches << {person: person, score: score}
    end

    matches
  end

  private

  LOGGER = Logger.new STDOUT

  FIELDS_TO_MATCH = %w{given_name family_name gender birth_date home_district
                       home_traditional_authority home_village}

  # These fields have to get a soundex generated
  SOUNDEX_FIELDS = %w{given_name family_name home_traditional_authority
                      home_village home_district}

  MINIMUM_SIMILARITY_SCORE = 0.8

  WHITE_SIMILARITY_SCORER = lambda { |a, b| WhiteSimilarity.similarity(a, b) }

  FIELD_SPECS = {
    "given_name" => {scorer: WHITE_SIMILARITY_SCORER},
    "family_name" => {scorer: WHITE_SIMILARITY_SCORER},
    "home_district" => {score: WHITE_SIMILARITY_SCORER},
    "home_village" => {scorer: WHITE_SIMILARITY_SCORER},
    "gender" => {scorer: WHITE_SIMILARITY_SCORER},
    "home_traditional_authority" => {scorer: WHITE_SIMILARITY_SCORER},
    "birth_date" => {scorer: WHITE_SIMILARITY_SCORER},    # Guard against typos
  }
end
