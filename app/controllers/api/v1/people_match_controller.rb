require "people_matching_service/bantu_soundex"

class Api::V1::PeopleMatchController < ApplicationController
  def get
    search_params = get_search_params

    if search_params.empty?
      message = {
        message: "One of family_name, given_name, birth_date, gender and attributes is required",
      }
      return render json: message, status: 400
    end
    same_soundex_pple = get_potential_duplicates(search_params['given_name'].soundex,
                                                 search_params['family_name'].soundex)

    #Remove special characters from search_params
    search_params['given_name'].match? /\A[a-zA-Z']*\z/
    search_params['family_name'].match? /\A[a-zA-Z']*\z/
    subject = ''

    subject << search_params['given_name']
    subject << search_params['family_name']
    subject << search_params['gender']
    subject << search_params['home_village']
    subject << search_params['home_traditional_authority']
    subject << search_params['home_district']
    subject << search_params['birthdate'].to_date.strftime('%Y-%m-%d').gsub('-', '')

    subject.gsub(/\s+/, "")

    matches = Parallel.map(same_soundex_pple) do | person |
      next if (person.first_name.blank? || person.last_name.blank? || person.gender.blank? || person.ancestry_village.blank? || person.ancestry_ta.blank? || person.ancestry_district.blank?)
      #Remove special characters from names
      person['first_name'].match? /\A[a-zA-Z']*\z/
      person['last_name'].match? /\A[a-zA-Z']*\z/

      potential_duplicate = ''
      potential_duplicate << person.first_name
      potential_duplicate << person.last_name
      potential_duplicate << person.gender
      potential_duplicate << person.ancestry_village
      potential_duplicate << person.ancestry_ta
      potential_duplicate << person.ancestry_district
      potential_duplicate << person.birthdate.to_date.strftime('%Y-%m-%d').gsub('-', '')


      score = (WhiteSimilarity.similarity(subject.gsub(/\s+/, "").downcase, potential_duplicate.gsub(/\s+/, "").downcase)).round(4)
      puts score
      if score >= 0.8
        json_person = convert_to_json(person)
        json_person.merge!(score: score)
      else
        nil
      end
    end
    render json: matches.compact.sort_by { |score| score[:score].to_i }.reverse
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
    permitted = super.permit(:family_name, :given_name, :birthdate, :gender,
                             attributes: PERSON_ATTRIBUTE_FIELDS)
    print "Permitted: #{permitted}\n"
    permitted
  end

  def get_potential_duplicates(first_name_soundex, last_name_soundex)
    same_soundex_pple = PersonDetail.where(first_name_soundex: first_name_soundex,
                                             last_name_soundex: last_name_soundex).select(:person_uuid, :first_name,
                                             :last_name,:gender,:birthdate,:ancestry_district, :ancestry_ta, :ancestry_village)
  end

  def convert_to_json(person)
     {
      person:{
      id: person.person_uuid,
      gender: person.gender,
      birthdate: person.birthdate,
      given_name: person.first_name,
      family_name: person.last_name,
      home_village: person.ancestry_village,
      home_traditional_authority: person.ancestry_ta,
      home_district: person.ancestry_district
      },
    }
  end

end
