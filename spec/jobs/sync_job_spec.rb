require 'rails_helper'

RSpec.describe SyncJob do
  describe '#push_footprints' do
    let(:job) do
      described_class.allocate.tap do |instance|
        instance.instance_variable_set(:@location, 1)
        instance.instance_variable_set(:@base_url, 'http://example.com/v1')
        instance.instance_variable_set(:@token, 'Bearer test-token')
      end
    end

    before do
      allow(RestClient).to receive(:post).and_return(double(code: 201))
    end

    def create_footprint(location_id:, synced: false)
      FootPrint.create!(
        user_id: 1,
        person_uuid: SecureRandom.uuid,
        program_id: 1,
        location_id: location_id,
        uuid: SecureRandom.uuid,
        encounter_datetime: Time.current,
        synced: synced
      )
    end

    it 'pushes unsynced footprints from every location for a MaHIS sync' do
      instance = job
      instance.instance_variable_set(:@is_mahis_sync, true)
      local_footprint = create_footprint(location_id: 1)
      other_location_footprint = create_footprint(location_id: 2)

      instance.push_footprints

      expect(local_footprint.reload.synced).to be(true)
      expect(other_location_footprint.reload.synced).to be(true)
      expect(RestClient).to have_received(:post).twice
    end

    it 'pushes only the configured location footprints for a facility sync' do
      instance = job
      instance.instance_variable_set(:@is_mahis_sync, false)
      local_footprint = create_footprint(location_id: 1)
      other_location_footprint = create_footprint(location_id: 2)

      instance.push_footprints

      expect(local_footprint.reload.synced).to be(true)
      expect(other_location_footprint.reload.synced).to be(false)
      expect(RestClient).to have_received(:post).once
    end
  end

  describe '#pull_new_records' do
    let(:location_id) { 1 }
    let(:base_url) { 'http://example.com' }
    let(:token) { 'Bearer test-token' }

    before do
      # Stub out the missing database.yml
      fake_yml = { dde_sync_config: { adapter: 'mysql2', database: 'test' } }.to_yaml
      allow(File).to receive(:read)
        .with("#{Rails.root}/config/database.yml")
        .and_return(fake_yml)

      # Allow YAML.load to work with our fake config
      allow(YAML).to receive(:load).and_call_original
      allow(YAML).to receive(:load)
        .with(fake_yml, aliases: true)
        .and_return(YAML.safe_load(fake_yml, permitted_classes: [Symbol], aliases: true))

      # Setup job with necessary instance variables
      subject.instance_variable_set(:@location_id, location_id)
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
          'npid' => 'XYZ123456', # Duplicate NPID
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
      expect do
        subject.pull_new_records
      end.not_to(change { PersonDetail.count })

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

      expect do
        subject.pull_new_records
      end.not_to(change { PersonDetail.count })

      error = SyncError.last
      expect(error.error).to include('Duplicate National ID')
      expect(error.error).to include('NATVVNAF')
    end
  end
end