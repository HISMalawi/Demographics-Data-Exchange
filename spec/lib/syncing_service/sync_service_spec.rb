require 'rails_helper'
require 'syncing_service/sync_service'

RSpec.describe SyncService do
  describe '.update_records_updates' do
    let(:update) do
      {
        person_uuid: 'missing-person',
        location_updated_at: 1,
        update_seq: 2,
        first_name: 'Updated'
      }
    end

    it 'returns not found without creating a tracker when the person does not exist' do
      result = described_class.update_records_updates(update)

      expect(result).to eq(status: 404, error: 'Person not found', person_uuid: 'missing-person')
      expect(PushTracker.where(site_id: 1, push_type: 'update')).to be_empty
    end

    it 'does not advance an existing tracker when the person does not exist' do
      tracker = PushTracker.create!(site_id: 1, push_seq: 1, push_type: 'update')

      result = described_class.update_records_updates(update)

      expect(result[:status]).to eq(404)
      expect(tracker.reload.push_seq).to eq(1)
    end
  end

  describe '.update_records_new' do
    let(:new_person) do
      {
        id: 2,
        person_uuid: 'new-person',
        npid: 'missing-npid',
        first_name: 'New',
        last_name: 'Person',
        gender: 'M',
        birthdate: Date.new(1990, 1, 1),
        date_registered: Time.current,
        last_edited: Time.current,
        location_created_at: 1,
        location_updated_at: 1,
        creator: 1,
        first_name_soundex: 'N',
        last_name_soundex: 'P'
      }
    end

    it 'returns not found without creating a person or tracker when the NPID is missing' do
      result = described_class.update_records_new(new_person)

      expect(result).to eq(status: 404, error: 'NPID not found', npid: 'missing-npid')
      expect(PersonDetail.unscoped.find_by_person_uuid('new-person')).to be_nil
      expect(PushTracker.where(site_id: 1, push_type: 'new')).to be_empty
    end

    it 'does not advance an existing tracker when the NPID is missing' do
      tracker = PushTracker.create!(site_id: 1, push_seq: 1, push_type: 'new')

      result = described_class.update_records_new(new_person)

      expect(result).to eq(status: 404, error: 'NPID not found', npid: 'missing-npid')
      expect(PersonDetail.unscoped.find_by_person_uuid('new-person')).to be_nil
      expect(tracker.reload.push_seq).to eq(1)
    end
  end

  describe '.save_errors' do
    let(:error) do
      {
        site_id: 1,
        incident_time: Time.current,
        error: 'Connection timed out',
        uuid: SecureRandom.uuid
      }
    end

    it 'returns the existing error instead of creating a duplicate with the same UUID' do
      existing_error = described_class.save_errors(error)
      duplicate_error = described_class.save_errors(error)

      expect(duplicate_error).to eq(existing_error)
      expect(existing_error.previously_new_record?).to be(true)
      expect(duplicate_error.previously_new_record?).to be(false)
      expect(SyncError.where(site_id: 1, error: 'Connection timed out').count).to eq(1)
    end

    it 'ignores changing numeric IDs in otherwise identical error messages' do
      existing_error = described_class.save_errors(
        error.merge(error: '511 Network Authentication Required 53915: {"msg":"Request source cannot be verified"}')
      )
      duplicate_error = described_class.save_errors(
        error.merge(
          uuid: SecureRandom.uuid,
          error: '511 Network Authentication Required 53913: {"msg":"Request source cannot be verified"}'
        )
      )

      expect(duplicate_error).to eq(existing_error)
      expect(SyncError.where(site_id: 1).count).to eq(1)
    end

    it 'ignores changing error_id values in otherwise identical error messages' do
      existing_error = described_class.save_errors(
        error.merge(error: 'msg: 500 Internal Server Error error_id: 1113460: response: ')
      )
      duplicate_error = described_class.save_errors(
        error.merge(
          uuid: SecureRandom.uuid,
          error: 'msg: 500 Internal Server Error error_id: 1113461: response: '
        )
      )

      expect(duplicate_error).to eq(existing_error)
      expect(SyncError.where(site_id: 1).count).to eq(1)
    end

    it 'creates a separate entry when the same error comes from another site' do
      first_error = described_class.save_errors(error)
      second_error = described_class.save_errors(error.merge(site_id: 2, uuid: SecureRandom.uuid))

      expect(second_error).not_to eq(first_error)
      expect(SyncError.where(error: 'Connection timed out').count).to eq(2)
    end
  end
end
