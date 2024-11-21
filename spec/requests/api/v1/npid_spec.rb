require 'swagger_helper'

RSpec.describe 'api/v1/npid', type: :request do

  path '/v1/assign_npids' do

    post('assign_npids npid') do
      tags 'NPID Actions'
      consumes 'application/json'
      parameter name: :npid, in: :body , schema: {
        type: :object,
        properties: {
          limit: { type: :integer },
          location_id: { type: :integer }
      },
        required: %w[limit location_id]
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
