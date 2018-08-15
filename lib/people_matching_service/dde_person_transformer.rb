require_relative "bantu_soundex"

# Converts a DDE person to a PersonDTO object used in this package.
class DDEPersonTransformer
  def self.transform(dde_person)
    person_dto = {id: dde_person[:doc_id]}

    TOP_LEVEL_FIELDS.inject(person_dto) do |person_dto, field|
      person_dto[field] = dde_person[field.to_sym]
      set_soundex_field! person_dto, field if SOUNDEX_FIELDS.include? field
      person_dto
    end

    ATTRIBUTE_FIELDS.inject(person_dto) do |person_dto, field|
      person_dto[field] = dde_person[:attributes][field.to_sym]
      set_soundex_field! person_dto, field if SOUNDEX_FIELDS.include? field
      person_dto
    end
  end

  private

  TOP_LEVEL_FIELDS = [:family_name, :given_name, :birth_date, :gender]
  ATTRIBUTE_FIELDS = [:home_district, :home_village, :home_traditional_authority]
  SOUNDEX_FIELDS = [:family_name, :given_name, :home_district, :home_village,
                    :home_traditional_authority]

  # Generates and sets a soundex field for the given field in person_dto
  def self.set_soundex_field!(person_dto, field)
    soundex_field = "#{field}_soundex".to_sym
    person_dto[soundex_field] = person_dto[field].soundex
  end
end
