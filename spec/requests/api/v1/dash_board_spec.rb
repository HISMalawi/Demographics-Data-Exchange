require 'swagger_helper'

RSpec.describe 'api/v1/dash_board', type: :request do
  path '/v1/location_npid_status/?location_id={location_id}' do
    get('Location NPID Status') do
      tags 'NPID Actions'
      consumes 'application/json'
      parameter name: :location_id, in: :path, type: :integer, description: 'location_id', required: true

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
