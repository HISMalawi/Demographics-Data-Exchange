require 'swagger_helper'

RSpec.describe 'api/v1/people_details', type: :request do
  path '/v1/add_person' do
    post('Create Person Details') do
      tags 'Person'
      consumes 'application/json'
      parameter name: :person, in: :body, schema: {
        type: :object,
        properties: {
          given_name: { type: :string },
          family_name: { type: :string },
          gender: { type: :string },
          birthdate: { type: :string, format: :date },
          birthdate_estimated: { type: :boolean },
          attributes: {
            type: :object,
            properties: {
                current_district: { type: :string },
                current_traditional_authority: { type: :string },
                current_village: { type: :string },
                home_district: { type: :string },
                home_village: { type: :string },
                home_traditional_authority: { type: :string },
                occupation: { type: :string }
              }
          }
        },
        required: %w[given_name family_name gender birthdate birthdate_estimated attributes home_district home_village
                     home_traditional_authority]
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

  path '/v1/search_by_name_and_gender?given_name={given_name}&family_name={family_name}&gender={gender}' do
    post('search_by_name_and_gender people_detail') do
      tags 'Person'
      parameter name: :given_name, in: :path, type: :string, description: 'given_name', required: true
      parameter name: :family_name, in: :path, type: :string, description: 'family_name', required: true
      parameter name: :gender, in: :path, type: :string, description: 'gender', required: true

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

  path '/v1/search_by_npid?npid={npid}' do
    post('search_by_npid people_detail') do
      tags 'Person'
      parameter name: :npid, in: :path, type: :string, description: 'npid', required: true
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

  path '/v1/search_by_doc_id?doc_id={doc_id}' do
    post('search_by_doc_id people_detail') do
      tags 'Person'
      parameter name: :doc_id, in: :path, type: :string, description: 'doc_id', required: true
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

  path '/v1/merge_people' do
    post('merge_people people_detail') do
      tags 'Deduplication'
      consumes 'application/json'
      parameter name: :person, in: :body, schema: {
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

  path '/v1/update_person' do
    post('update_person people_detail') do
      tags 'Person'
      consumes 'application/json'
      parameter name: :person, in: :body, schema: {
        type: :object,
        properties: {
          given_name: { type: :string },
          family_name: { type: :string },
          gender: { type: :string },
          birthdate: { type: :string, format: :date },
          birthdate_estimated: { type: :boolean },
          attributes: {
            type: :object,
            properties: {
                current_district: { type: :string },
                current_traditional_authority: { type: :string },
                current_village: { type: :string },
                home_district: { type: :string },
                home_village: { type: :string },
                home_traditional_authority: { type: :string },
                occupation: { type: :string }
              }
          },
          npid: { type: :string },
          doc_id: { type: :string }
        },
        required: %w[doc_id]
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

  path '/v1/void_person/{doc_id}?void_reason={void_reason}' do
    # You'll want to customize the parameter types...
    parameter name: 'doc_id', in: :path, schema: {
      doc_id: { type: :string },
      void_reason: { type: :string }
    }

    delete('void people_detail') do
      tags 'Person'
      consumes 'application/json'
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

  path '/v1/reassign_npid?doc_id={doc_id}' do
    post('reassign_npid people_detail') do
      tags 'Person'
      consumes 'application/json'
      parameter name: :person, in: :path, type: :string, description: 'doc_id', required: true

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
