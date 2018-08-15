require "people_matching_service/elasticsearch_client"
require "people_matching_service/elasticsearch_person_dao"
require "people_matching_service/people_matching_service"

class Api::V1::PeopleMatchController < ApplicationController
  def get
    search_params = get_search_params

    if search_params.empty?
      message = {
        message: "One of family_name, given_name, birth_date, gender and attributes is required",
      }
      return render json: message, status: 400
    end

    es_host, es_port = Rails.application.config.elasticsearch

    es_client = ElasticsearchClient.new host: es_host, port: es_port
    es_person_dao = ElasticsearchPersonDAO.new es_client
    matching_service = PeopleMatchingService.new es_person_dao

    matches = matching_service.find_duplicates search_params, use_soundex: true
    render json: matches
  end

  private

  # Fields allowed as person attributes
  PERSON_ATTRIBUTE_FIELDS = %w{home_village home_traditional_authority home_district}

  def get_search_params
    permitted_params = params
    params_hash = permitted_params.to_hash
    print "#{params_hash}\n"

    params_hash.to_hash.inject({}) do |person_dto, fv_pair|
      field, value = fv_pair
      next person_dto unless value

      if field == "attributes"
        # PersonDTO must have person attribes as top level fields
        value.each do |attribute, attribute_value|
          print "#{attribute} => #{attribute_value}\n"
          break unless PERSON_ATTRIBUTE_FIELDS.include? attribute and attribute_value
          person_dto[attribute] = attribute_value
        end
      else
        person_dto[field] = value
      end

      person_dto
    end
  end

  def params
    permitted = super.permit(:family_name, :given_name, :birth_date, :gender,
                             attributes: PERSON_ATTRIBUTE_FIELDS)
    print "Permitted: #{permitted}\n"
    permitted
  end
end
