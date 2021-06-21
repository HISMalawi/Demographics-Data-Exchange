require 'swagger_helper'

describe 'User API' do
  
  	path 'v1/register' do

		post 'Registers User' do
			tags 'User'
			consumes 'application/json'
			parameter name: :user, in: :body, schema: {
			type: :object,
			properties: {
			username: 			    {type: :string},
			password:   			{type: :string},
			location: 			    {type: :integer},
			email: 				    {type: :string},
			},
			required: ['username','password','location','email']
			}
	
			response '201', 'User created successfully' do
				let(:user) {
				{
					username:  	'username',
					password:    'password',
					location:    345,
					email:        'example@email.com',
					created_at: Time.now,
					updated_at: Time.now,
				}
				}
				run_test!
			end

		end
    end
end

describe 'User API' do
  
    path 'v1/login' do
        post 'User Login' do
            tags 'User'
			consumes 'application/json'
			parameter name: :user, in: :body, schema: {
			type: :object,
			properties: {
			username: 			    {type: :string},
			password:   			{type: :string},
			},
			required: ['username','password','location','email']
			}
	
			response '200', 'success' do
				let(:user) {
				{
					message:  	     'Login succesfull',
					access_token:    'yJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE1Mjk3Njc0MjV9.EDR8G6J94Qko5CDeblXkKidzNye2IE706z9T4p_bwTo',
				}
				}
				run_test!
			end
        end 
  	end 
end

describe 'User API' do
  
    path 'v1/verify_token/' do
        post 'verify token' do
            tags 'User'
			consumes 'application/json'
			parameter name: :user, in: :body, schema: {
			type: :object,
			properties: {
			token: 			    {type: :string},
			},
			required: ['token']
			}
	
			response '200', 'success' do
				let(:user) {
				{
                    status:         '200',
					message:  	     'successful',
				}
				}
				run_test!
			end
        end 
  	end 
end

