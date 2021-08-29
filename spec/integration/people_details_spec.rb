require 'swagger_helper'

describe 'Person Details API' do
  
  path '/api/v1/people_details' do

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
  		  	gender:                 {type: :boolean},
  		  	ancestry_district:      {type: :integer},
  		  	ancestry_ta:  			{type: :integer},
  		  	ancestry_village:       {type: :integer},
  		  	home_district:          {type: :integer},
  		  	home_ta:                {type: :integer},
  		  	home_village:           {type: :integer},
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
  		},

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