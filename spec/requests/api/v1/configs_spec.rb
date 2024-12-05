require 'swagger_helper'

RSpec.describe 'api/v1/configs', type: :request do

  path '/v1/configs' do

    put('update config') do
      tags 'Configurations'
      parameter name: :config, in: :query, type: :string, description: 'config', required: true
      
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
