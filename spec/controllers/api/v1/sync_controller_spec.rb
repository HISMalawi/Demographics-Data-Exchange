require 'rails_helper'

RSpec.describe Api::V1::SyncController, type: :controller do
  before do
    allow_any_instance_of(described_class).to receive(:authenticate_request)
    allow_any_instance_of(described_class).to receive(:update_socket_dashboard)
    allow_any_instance_of(described_class).to receive(:update_location_npids)
    request.headers['X-Source-System'] = 'MaHIS'
  end

  describe '#pushed_updates' do
    it 'logs the unexpected error and returns an internal server error' do
      allow(SyncService).to receive(:update_records_updates).and_raise(ArgumentError, 'unexpected failure')
      expect(Rails.logger).to receive(:error).with(include('ArgumentError: unexpected failure'))

      post :pushed_updates, params: { person_uuid: 'person-uuid', location_updated_at: 1 }

      expect(response).to have_http_status(:internal_server_error)
      expect(JSON.parse(response.body)).to eq('msg' => 'Something went wrong')
    end

    it 'returns any non-success status returned by the sync service' do
      allow(SyncService).to receive(:update_records_updates).and_return(
        status: 422, error: 'Invalid update'
      )

      post :pushed_updates, params: { person_uuid: 'person-uuid', location_updated_at: 1 }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to eq('error' => 'Invalid update')
    end
  end

  describe '#pushed_updates_new' do
    it 'logs the unexpected error and returns an internal server error' do
      allow(SyncService).to receive(:update_records_new).and_raise(ArgumentError, 'unexpected failure')
      expect(Rails.logger).to receive(:error).with(include('ArgumentError: unexpected failure'))

      post :pushed_updates_new, params: { person_uuid: 'person-uuid', location_updated_at: 1 }

      expect(response).to have_http_status(:internal_server_error)
      expect(JSON.parse(response.body)).to eq('msg' => 'Something went wrong')
    end

    it 'returns any non-success status returned by the sync service' do
      allow(SyncService).to receive(:update_records_new).and_return(
        status: 422, error: 'Invalid update'
      )

      post :pushed_updates_new, params: { person_uuid: 'person-uuid', location_updated_at: 1 }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to eq('error' => 'Invalid update')
    end
  end
end
