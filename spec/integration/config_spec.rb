require 'swagger_helper'

describe 'Configs API' do
    path '/v1/create_config' do
        post 'Creates configs' do
            tags 'Configs'
            consumes 'application/json'
            parameter name: :config, in: :body, schema: {
               type: :object,
               properties: {
               config_name:           {type: :string},
               config_value:          {type: :string},
               description:           {type: :string},
               uuid:                  {type: :binary},
               created_at:            {type: :datetime},
               updated_at:            {type: :datetime},
               },
               required:  ['config', 'config_value', 
               'description','uuid','created_at','updated_at']
            }

            response '201', 'configs created' do
                let(:config){
                {
                    config_name:        'something',
                    config_value:       'some value',
                    description:        'some description',
                    uuid:               '72928cba-f84f-11ea-af62-00155d46651c',
                    created_at:         Time.now,
                    updated_at:         Time.now,
                }
                }
                run_test!
            end
        end
    end
end