require 'rails_helper'

RSpec.describe SyncJob do
  describe '#pull_new_records' do
    let(:location_id) { 1 }
    let(:base_url) { 'http://example.com' }
    let(:token) { 'Bearer test-token' }

    before do
      # Setup job with necessary instance variables
      subject.instance_variable_set(:@location, location_id)
      subject.instance_variable_set(:@base_url, base_url)
      subject.instance_variable_set(:@token, token)

      # Create an existing person with a specific NPID
      PersonDetail.create!(
        person_uuid: 'existing-uuid',
        npid: 'XYZ123456',
        birthdate: '1990-01-01',
        gender: 'M',
        first_name: 'John',
        last_name: 'Doe',
        first_name_soundex: 'Y',
        last_name_soundex: 'DDD',
        creator: 1,
        location_created_at: 1,
        location_updated_at: 1,
        date_registered: Date.today,
        last_edited: Date.today
      )

      # Stub pull_seq config
      Config.create!(config: 'pull_seq_new', config_value: '1', description: 'test', uuid: 'XCDH')

      # Simulate remote server response with duplicate NPID
      response = [
        {
          'id' => 2,
          'person_uuid' => 'new-uuid',
          'npid' => 'XYZ123456',  # Duplicate NPID
          'birthdate' => '1990-01-01',
          'gender' => 'M',
          'first_name' => 'Johnny',
          'last_name' => 'Doeson',
          'created_at' => Time.now,
          'updated_at' => Time.now
        }
      ].to_json

      allow(RestClient).to receive(:get).and_return(response)
    end

    it 'does not create new record if NPID already exists and logs an error' do
      expect {
        subject.pull_new_records
      }.not_to(change { PersonDetail.count })

      error = SyncError.last
      expect(error.error).to include('Duplicate NPID')
      expect(error.error).to include('XYZ123456')
      expect(error.error).to include('new-uuid')
    end

    it 'does not create new record if National ID exits and logs an error' do
        # Create an existing person with a specific National ID
        PersonDetail.create!(
          person_uuid: 'existing-uuid1',
          npid: 'NEW123456',
          national_id: 'NATVVNAF',
          birthdate: '1990-01-01',
          gender: 'M',
          first_name: 'John',
          last_name: 'Doe',
          first_name_soundex: 'Y',
          last_name_soundex: 'DDD',
          creator: 1,
          location_created_at: 1,
          location_updated_at: 1,
          date_registered: Date.today,
          last_edited: Date.today
        )
        # Override the stubbed response with a unique NPID
        response = [
          {
            'id' => 3,
            'person_uuid' => 'unique-uuid',
            'npid' => 'DUPLICATE_NATIONAL-ID',
            'national_id' => 'NATVVNAF',
            'birthdate' => '1992-02-02',
            'gender' => 'F',
            'first_name' => 'Jane',
            'last_name' => 'Smith',
            'created_at' => Time.now,
            'updated_at' => Time.now
          }
        ].to_json

        allow(RestClient).to receive(:get).and_return(response)

        expect {
          subject.pull_new_records
        }.not_to(change { PersonDetail.count })

        error = SyncError.last
        expect(error.error).to include('Duplicate National ID')
        expect(error.error).to include('NATVVNAF')
        expect(error.error).to include('DUPLICATE_NATIONAL-ID')
    end
  end
end
