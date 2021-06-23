require 'swagger_helper'

describe 'Person Details API' do
  
  	path '/v1/add_person' do

		post 'Creates person details' do
			tags 'People'
			consumes 'application/json'
			parameter name: :person, in: :body, schema: {
			type: :object,
			properties: {
			given_name: 			{type: :string},
			family_name: 			{type: :string},
			middle_name: 			{type: :string},
			birthdate: 				{type: :date},
			birthdate_estimated: 	{type: :boolean},
			gender:                 {type: :string},
			ancestry_district:      {type: :string},
			ancestry_ta:  			{type: :string},
			ancestry_village:       {type: :string},
			home_district:          {type: :string},
			home_ta:                {type: :string},
			home_village:           {type: :string},
			npid:                   {type: :string},
			person_uuid:            {type: :binary},
			date_registered:        {type: :datetime},
			last_edited:            {type: :datetime},
			location_created_at:    {type: :integer},
			location_updated_at:    {type: :integer},
			},

			required: ['first_name','last_name','gender',
					'npid','person_uuid','date_registered',
					'last_edited','location_created_at','location_updated_at']
			}
	
			response '201', 'person details created' do
				let(:person) {
				{
					given_name:  	'test_person',
					family_name:    'test_family_name',
					gender:         true,
					npid:           'J3MEVX',
					person_uuid:    '72928cba-f84f-11ea-af62-00155d46651c',
					date_registered: Time.now,
					last_edited: 	 Time.now,
					location_created_at: 363,
					location_updated_at: 363,
				}
				}
				run_test!
			end

		end
  	end 
end

describe 'Person Details API' do
  
	path '/v1/search_by_name_and_gender' do

	  post 'Search by name and gender' do
		  tags 'People'
		  consumes 'application/json'
		  parameter name: :person, in: :body, schema: {
		  type: :object,
		  properties: {
		  given_name: 			{type: :string},
		  family_name: 			{type: :string},
		  gender:                 {type: :string},
		  },
		  required: ['given_name','family_name','gender']
		  }
  
		  response '200', 'success' do
			  let(:person) {
			  {
				  given_name:  	       'test_person',
				  family_name:         'test_family_name',
				  middle_name:         '',
				  gender:              'Male',
				  birthdate:	       '0000-00-00',
				  birthdate_estimated: false,
				  current_village:     'village',
				  home_district:       'my home disrict',
				  home_village:        'my-village',
				  identifier:          '{"HTN number":"HTN 000"}],"npid":"000000","doc_id":"000000000000000000000000000000"}',
			  }
			  }
			  run_test!
		  end

		  response '401', 'Failed to create person' do
			let(:person) {
				 { 
					 
				 } }
			run_test!
		  end

		  response '500', 'No token for authorization' do
			let(:person) {
				 { 
					 
				 } }
			run_test!
		  end
		  

	  end
	end 
end

describe 'Person Details API' do
  
	path '/v1/search_by_name_and_gender' do

	  post 'Search by name and gender' do
		  tags 'People'
		  consumes 'application/json'
		  parameter name: :person, in: :body, schema: {
		  type: :object,
		  properties: {
		  given_name: 			{type: :string},
		  family_name: 			{type: :string},
		  gender:                 {type: :string},
		  },
		  required: ['given_name','family_name','gender']
		  }
  
		  response '200', 'success' do
			  let(:person) {
			  {
				  given_name:  	       'test_person',
				  family_name:         'test_family_name',
				  middle_name:         '',
				  gender:              'Male',
				  birthdate:	       '0000-00-00',
				  birthdate_estimated: false,
				  current_village:     'village',
				  home_district:       'my home disrict',
				  home_village:        'my-village',
				  identifier:          '{"HTN number":"HTN 000"}],"npid":"000000","doc_id":"000000000000000000000000000000"}',
			  }
			  }
			  run_test!
		  end

		  response '401', 'invalid request' do
			let(:person) {
				 { 
					 
				 } }
			run_test!
		  end

		  response '500', 'No token for authorization' do
			let(:person) {
				 { 
					 
				 } }
			run_test!
		  end
		  


	  end
	end 
end

describe 'Person Details API' do
  
	path '/v1/search_by_npid' do

	  post 'Search by name npid' do
		  tags 'People'
		  consumes 'application/json'
		 # security [Bearer: {}]
		#  parameter name: :access_token, in: :header, type: :string
		  parameter name: :person, in: :body, schema: {
		  type: :object,
		  properties: {
		  npid: 			    {type: :string},
		  doc_id: 			    {type: :string},
		  },
		  required: ['npid','doc_id']
		  }
  
		  response '200', 'success' do
			  let(:person) {
			  {
				  given_name:  	       'test_person',
				  family_name:         'test_family_name',
				  middle_name:         '',
				  gender:              'Male',
				  birthdate:	       '0000-00-00',
				  birthdate_estimated: false,
				  current_village:     'village',
				  home_district:       'my home disrict',
				  home_village:        'my-village',
				  identifier:          '{"HTN number":"HTN 000"}],"npid":"000000","doc_id":"000000000000000000000000000000"}',
			  }
			  }
			  run_test!
		  end

		  response '401', 'invalid request' do
			let(:person) {
				 { 
					 
				 } }
			run_test!
		  end

		  response '500', 'No token for authorization' do
			let(:person) {
				 { 
					 
				 } }
			run_test!
		  end
		  


	  end
	end 
end
