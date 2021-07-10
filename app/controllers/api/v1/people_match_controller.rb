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

    subject.gsub(/\s+/, "")

    matches = Parallel.map(same_soundex_pple) do | person |
      #Remove special characters from names
      person['first_name'].match? /\A[a-zA-Z']*\z/
      person['last_name'].match? /\A[a-zA-Z']*\z/

      potential_duplicate = ''
      potential_duplicate << person.first_name
      potential_duplicate << person.last_name
      potential_duplicate << person.gender
      potential_duplicate << person.home_village
      potential_duplicate << person.home_ta
      potential_duplicate << person.home_district


      score = calculate_similarity_score(subject.gsub(/\s+/, "").downcase,potential_duplicate.gsub(/\s+/, "").downcase)
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
    permitted = super.permit(:family_name, :given_name, :birth_date, :gender,
                             attributes: PERSON_ATTRIBUTE_FIELDS)
    print "Permitted: #{permitted}\n"
    permitted
  end

  def calculate_similarity_score(string_A,string_B)
    #Calulating % Similarity using the formula %RSD = (SD/max_ed)%
    #Where SD = Max(length(A),Length(B)) - Edit Distance
    #SD = Similartiy Distance
    #ed = edit Distance
    #max_ed = maximum edit distance
    #RSD

    ed = DamerauLevenshtein.distance(string_A,string_B)

    if string_A.size >= string_B.size
      max_ed = string_A.size
    else
      max_ed = string_B.size
    end

    sd = max_ed - ed

    score = (sd/max_ed.to_f).round(2)
  end

  def get_potential_duplicates(first_name_soundex, last_name_soundex)
    same_soundex_pple = PersonDetail.where(first_name_soundex: first_name_soundex,
                                             last_name_soundex: last_name_soundex).select(:person_uuid, :first_name,
                                             :last_name,:gender,:birthdate,:home_district, :home_ta, :home_village)
  end

  def convert_to_json(person)
     {
      person:{
      id: person.person_uuid,
      gender: person.gender,
      birthdate: person.birthdate,
      given_name: person.first_name,
      family_name: person.last_name,
      home_village: person.home_village,
      home_traditional_authority: person.home_ta,
      home_district: person.home_district
      },
    }
  end

end
