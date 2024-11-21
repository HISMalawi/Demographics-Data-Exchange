require 'swagger_helper'

RSpec.describe 'api/v1/people_match', type: :request do

  path '/v1/search/people' do

    post('get people_match') do
      tags 'Deduplication'
      consumes 'application/json'
      parameter name: :person, in: :body, schema: {
        type: :object,
        properties: {
          given_name: { type: :string },
          family_name: { type: :string },
          birth_date: { type: :date },
          gender: { type: :string },
          ancestry_district: { type: :string },
          ancestry_traditional_authority: { type: :string },
          ancestry_village: { type: :string }
      },
        required: %w[given_name family birth_date gender ancestry_district ancestry_traditional_authority 
                     ancestry_village]
    }
      response(200, 'successful') do

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end
end
