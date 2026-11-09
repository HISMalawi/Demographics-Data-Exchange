require 'rails_helper'
require 'syncing_service/sync_service'

RSpec.describe SyncService do
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
