require 'swagger_helper'

describe 'Sync API' do
  
  	path '/v1/person_changes' do

		get 'Pull Updates' do
			tags 'Sync'
			consumes 'application/json'
			parameter name: :user, in: :body, schema: {
			type: :object,
			properties: {
			site_id: 			{type: :string},
			pull_seq:   	    {type: :integer},
			},
			required: ['site_id','pull_seq']
			}
	
			response '200', 'Records pulled successfully' do
				let(:user) {
				{
					
				}
				}
				run_test!
			end
		end
    end
end


describe 'Sync API' do
  
    path '/v1/push_changes' do

      post 'Push Updates' do
          tags 'Sync'
          consumes 'application/json'
          parameter name: :user, in: :body, schema: {
          type: :object,
          properties: {
            first_name:                        {type: :string},                        
            middle_name:                       {type: :string},  
            gender:                            {type: :string},  
            current_village:                   {type: :string},
            current_traditional_authority:     {type: :string},
            current_district:                  {type: :string},
            home_village:                      {type: :string},
            home_traditional_authority:        {type: :string},
            home_district:                     {type: :string},
            birthdate:                         {type: :date},                    
            birthdate_estimated:               {type: :boolean},               
            person_uuid:                       {type: :binary},
            npid:                              {type: :string},
            date_registered:                   {type: :datetime},
            last_edited:                       {type: :datetime},
            location_created_at:               {type: :integer},
            location_updated_at:               {type: :integer},
            creator:                           {type: :integer},
            home_ta:                           {type: :string},
            ancestry_village:                  {type: :string},
            ancestry_ta:                       {type: :string},
            ancestry_district:                 {type: :string},
          },
          required: ['first_name','gender',
          'npid','person_uuid','date_registered',
          'last_edited','location_created_at','location_updated_at']
          }
  
          response '200', 'Records pushed successfully' do
              let(:user) {
              {
                  
              }
              }
              run_test!
          end
      end
  end
end

describe 'Sync API' do
  
    path '/v1/pull_npids' do

      get 'Pull npids' do
          tags 'Sync'
          consumes 'application/json'
          parameter name: :user, in: :body, schema: {
          type: :object,
          properties: {
          npids_seq: 			{type: :integer},
          },
          required: ['npids']
          }
  
          response '200', 'npids pulled successfully' do
              let(:user) {
              {
                  
              }
              }
              run_test!
          end
      end
  end
end




