class PersonDAO
  def initialize
    @people = {}
  end

  def get(id)
    @people[id]
  end

  def save(person)
    @people[person["id"]] = person
  end

  def search(data)
    @people.values.find_all do |person|
      search_params_match_person? data, person
    end
  end

  private

  def search_params_match_person?(params, person)
    params.inject(true) do |accum, hash_item|
      field, value = hash_item
      person_value = person[field]
      break false unless person_value and accum
      accum and (person_value.include? value or value.include? person_value)
    end
  end
end
