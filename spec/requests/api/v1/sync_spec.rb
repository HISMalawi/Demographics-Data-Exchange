require 'swagger_helper'

RSpec.describe 'api/v1/sync', type: :request do

  path '/v1/person_changes_new' do

    get('pull_updates_new sync') do
      tags 'Sychronization'
      parameter name: :location_id, in: :query, type: :integer, description: 'location_id', required: true
      parameter name: :pull_seq, in: :query, type: :integer, description: 'pull_seq', required: true
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

  path '/v1/person_changes_updates' do

    get('pull_updates sync') do
      tags 'Sychronization'
      parameter name: :location_id, in: :query, type: :integer, description: 'location_id', required: true
      parameter name: :pull_seq, in: :query, type: :integer, description: 'pull_seq', required: true
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

  path '/v1/push_changes_new' do

    post('pushed_updates_new sync') do
      tags 'Sychronization'
      parameter name: :location_id, in: :query, type: :integer, description: 'location_id', required: true
      parameter name: :person, in: :body, schema: {
        type: :object,
        properties: {
          id: { type: :integer },
          first_name: { type: :string },
          last_name: { type: :string },
          middle_name: { type: :string },
          birthdate: { type: :date },
          birthdate_estimated: { type: :boolean },
          gender: { type: :string },
          ancestry_district: { type: :string },
          ancestry_ta: { type: :string },
          ancestry_village: { type: :string },
          home_district: { type: :string },
          home_ta: { type: :string },
          home_village: { type: :string },
          npid: { type: :string },
          person_uuid: { type: :string },
          date_registered: { type: :datetime },
          last_edited: { type: :datetime },
          location_created_at: { type: :integer },
          location_updated_at: { type: :integer },
          created_at: { type: :datetime },
          updated_at: { type: :datetime },
          creator: { type: :integer },
          voided: { type: :boolean },
          voided_by: { type: :integer },
          date_voided: { type: :datetime },
          void_reason: { type: :string },
          first_name_soundex: { type: :string },
          last_name_soundex: { type: :string }
        },
        required: %w[person_uuid first_name last_name birthdate birthdate_est ancestor_district ancestor_ta ancestor_village]
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

  path '/v1/push_changes_updates' do

    post('pushed_updates sync') do
      tags 'Sychronization'
      parameter name: :location_id, in: :query, type: :integer, description: 'location_id', required: true
      parameter name: :person, in: :body, schema: {
        type: :object,
        properties: {
          id: { type: :integer },
          first_name: { type: :string },
          last_name: { type: :string },
          middle_name: { type: :string },
          birthdate: { type: :date },
          birthdate_estimated: { type: :boolean },
          gender: { type: :string },
          ancestry_district: { type: :string },
          ancestry_ta: { type: :string },
          ancestry_village: { type: :string },
          home_district: { type: :string },
          home_ta: { type: :string },
          home_village: { type: :string },
          npid: { type: :string },
          person_uuid: { type: :string },
          date_registered: { type: :datetime },
          last_edited: { type: :datetime },
          location_created_at: { type: :integer },
          location_updated_at: { type: :integer },
          created_at: { type: :datetime },
          updated_at: { type: :datetime },
          creator: { type: :integer },
          voided: { type: :boolean },
          voided_by: { type: :integer },
          date_voided: { type: :datetime },
          void_reason: { type: :string },
          first_name_soundex: { type: :string },
          last_name_soundex: { type: :string }
        },
        required: %w[person_uuid first_name last_name birthdate birthdate_est ancestor_district ancestor_ta ancestor_village]
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

  path '/v1/push_footprints' do

    post('pushed_footprints sync') do
      tags 'Sychronization'
      parameter name: :location_id, in: :query, type: :integer, description: 'location_id', required: true
      parameter name: :footprint, in: :body, schema: {
        type: :object,
        properties: {
          user_id: { type: :integer },
          person_id: { type: :string },
          program_id: { type: :string },
          loaction_id: { type: :string },
          uuid: { type: :string }
       },
       required: %w[user_id person_id program_id location_id uuid]
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

  path '/v1/pull_npids' do
    get('pull_npids sync') do
      tags 'Sychronization'
      parameter name: :site_id, in: :query, type: :integer, description: 'site_id', required: true
      parameter name: :npid_seq, in: :query, type: :integer, description: 'npid_seq', required: true
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

  path '/v1/push_errors' do
    post('Push Errors') do
      tags 'Sychronization'
      consumes 'application/json'
      parameter name: :sync_errors, in: :body, schema: {
        type: :object,
        properties: {
          id: { type: :integer },
          site_id: { type: :integer },
          incident_time: { type: :string, format: :date_time },
          error: { type: :string },
          uuid: { type: :string },
          created_at: { type: :string, format: :date_time},
          updated_at: {type: :string, format: :date_time}
        }
      }
      response(201, 'sucessful') do
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
