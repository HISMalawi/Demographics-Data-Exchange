require_relative "../dde_person_transformer"
require_relative "../people_matching_service"
require_relative "../mocks/person_dao"

RSpec.describe "PeopleMatchingService" do
  before do
    @person_dao = PersonDAO.new
    PEOPLE.each do |person|
      @person_dao.save person
    end
  end

  describe "find_duplicates" do
    it "should retrieve partial matches" do
      matching_service = PeopleMatchingService.new @person_dao
      search_data = person_to_search_data(PEOPLE[0])
      matches = matching_service.find_duplicates search_data, threshold: 0.75

      expect(matches.size).to eq(2)
      expect((matches[0][:score] * 100).round).to eq(100)   # Expect a perfect match
      expect((matches[1][:score] * 100).round).to be > 90   # Expect a 90% match
      matches.each do |match|
        expect(["0", "1"]).to include(match[:person]["id"])
      end
    end

    it "should retrieve partial matches using soundex" do
      matching_service = PeopleMatchingService.new @person_dao
      # Name is Landi Fubah, expecting it to Match Random Foobar
      search_data = person_to_search_data(PEOPLE[4])
      matches = matching_service.find_duplicates search_data, use_soundex: true, threshold: 0.75

      expect(matches.size).to eq(3)
      matches.each do |match|
        expect(["0", "1", "4"]).to include(match[:person]["id"])
      end
    end
  end

  private

  PEOPLE = [
    {
      "id" => "0",
      "given_name" => "Rand",
      "given_name_soundex" => "R53",
      "family_name" => "Foobar",
      "family_name_soundex" => "F14",
      "birthdate" => "1990/01/01",
      "gender" => "Male",
      "home_district" => "Blantyre",
      "home_district_soundex" => "B453",
      "home_village" => "Machinjiri",
      "home_village_soundex" => "N957",
      "home_traditional_authority" => "T/A Machinjiri",
      "home_traditional_authority_soundex" => "T595",
    },
    {
      "id" => "1",
      "given_name" => "Random",
      "given_name_soundex" => "R535",
      "family_name" => "Foobar",
      "family_name_soundex" => "F14",
      "birthdate" => "1990/01/01",
      "gender" => "Male",
      "home_district" => "Blantyre",
      "home_district_soundex" => "B453",
      "home_village" => "Machinjiri",
      "home_village_soundex" => "N957",
      "home_traditional_authority" => "T/A Machinjiri",
      "home_traditional_authority_soundex" => "T595",
    },
    {
      "id" => "2",
      "given_name" => "Stochastic",
      "given_name_soundex" => "Z396",
      "family_name" => "Foobar",
      "family_name_soundex" => "F14",
      "birthdate" => "1990/01/01",
      "gender" => "Male",
      "home_district" => "Blantyre",
      "home_district_soundex" => "B453",
      "home_village" => "Machinjiri",
      "home_village_soundex" => "N957",
      "home_traditional_authority" => "T/A Machinjiri",
      "home_traditional_authority_soundex" => "T595",
    },
    {
      "id" => "3",
      "given_name" => "Rand",
      "given_name_soundex" => "R53",
      "family_name" => "Foobar",
      "family_name_soundex" => "F14",
      "birthdate" => "2001/10/10",
      "gender" => "Female",
      "home_village" => "Bwaila",
      "home_village_prefix" => "B84",
      "home_district" => "Lilongwe",
      "home_district_prefix" => "R452",
      "home_traditional_authority" => "Random LL T/A",
      "home_traditional_authority_soundex" => "R535",
    },
    {
      "id" => "4",
      "given_name" => "Landi",
      "given_name_soundex" => "R53",
      "family_name" => "Fubah",
      "family_name_soundex" => "F1",
      "birthdate" => "1990/01/01",
      "gender" => "Male",
      "home_district" => "Blantyre",
      "home_district_soundex" => "B453",
      "home_village" => "Machinjiri",
      "home_village_soundex" => "N957",
      "home_traditional_authority" => "T/A Machinjiri",
      "home_traditional_authority_soundex" => "T595",
    },
  ]

  def person_to_search_data(person)
    {
      "given_name" => person["given_name"],
      "family_name" => person["family_name"],
      "birthdate" => person["birthdate"],
      "home_district" => person["home_district"],
      "home_village" => person["home_village"],
      "home_traditional_authority" => person["home_traditional_authority"],
    }
  end
end
