require 'swagger_helper'

RSpec.describe 'api/v1/merge', type: :request do

  path '/v1/rollback_merge' do

    post('rollback_merge merge') do
      tags 'Deduplication'
      consumes 'application/json'
      parameter name: :roll_back, in: :body, schema: {
        type: :object,
        properties: {
          primary_person_doc_id: { type: :string },
          secondary_person_doc_id: { type: :string }
        },
        required: %w[primary_person_doc_id secondary_person_doc_id]
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
