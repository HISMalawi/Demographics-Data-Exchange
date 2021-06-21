require 'rest-client'

@host = Config.find_by_config('host').config_value
@port = Config.find_by_config('peer_port').config_value
@username = Config.find_by_config('sync_user').config_value
@pwd = Config.find_by_config('sync_pwd').config_value
@location = User.find_by_username(@username)['location_id'].to_i

def authenticate
    url = "http://#{@host}:#{@port}/v1/login?username=#{@username}&password=#{@pwd}"

    token = JSON.parse(RestClient.post(url,headers={}))['access_token']
end

def token_valid(token)
  url = "http://#{@host}:#{@port}/v1/verify_token"

  response = JSON.parse(RestClient.post(url,{'token' => token}.to_json, {content_type: :json, accept: :json}))['message']

  if response == 'Successful'
  	return true
  else
  	return false
  end
end

def pull_records
  pull_seq = Config.find_by_config('pull_seq')['config_value'].to_i
  url = "http://#{@host}:#{@port}/v1/person_changes?site_id=#{@location}&pull_seq=#{pull_seq}"

  updates = JSON.parse(RestClient.get(url,headers={Authorization: authenticate }))

  updates.each do |record|
  	person = PersonDetail.find_by(npid: record['npid'],person_uuid: record['person_uuid'])
    pull_seq = record['id']
    record.delete('id')
    record.delete('created_at')
    record.delete('updated_at')
    ActiveRecord::Base.transaction do
    	if person.blank?
        PersonDetail.create!(record)
    	else
          PersonDetail.create!(record)
          audit_record = JSON.parse(person.to_json)
          audit_record.delete('id')
          audit_record.delete('created_at')
          audit_record.delete('updated_at')
          PersonDetailsAudit.create!(audit_record)
          person.destroy!
    	end
  	  Config.where(config: 'pull_seq').update(config_value: pull_seq)
    end
  end
end

def pull_npids
  npid_seq = Config.find_by_config('npid_seq')['config_value'].to_i
  url = "http://#{@host}:#{@port}/v1/pull_npids?site_id=#{@location}&npid_seq=#{npid_seq}"

  npids = JSON.parse(RestClient.get(url,headers={Authorization: authenticate }))

  unless npids.blank?
    npids.each do |npid|
      next if LocationNpid.find_by_npid(npid['npid'])
      ActiveRecord::Base.transaction do
        LocationNpid.create!(location_id: npid['location_id'],
                             npid: npid['npid'],
                             assigned: npid['assigned'])
        Config.where(config: 'npid_seq').update(config_value: npid['id'])
      end
    end
  end

end


def push_records
  url = "http://#{@host}:#{@port}/v1/push_changes"

	push_seq = Config.find_by_config('push_seq')['config_value'].to_i

  records_to_push = PersonDetail.where('person_details.id > ? AND person_details.location_updated_at = ?', push_seq,@location).order(:id)

  #PUSH UPDATES
  records_to_push.each do | record |
    begin
      response = JSON.parse(RestClient.post(url,format_payload(record), headers={Authorization: authenticate }))
      Config.find_by_config('push_seq').update(config_value: record.id.to_i) if response['status'] == 200
    rescue => e
        File.write("#{Rails.root}/log/sync_err.log", e, mode: 'a')
        exit
    end
  end

end

def format_payload(person)
  payload =  {
              "id": person.id,
              "last_name": person.last_name,
              "first_name": person.first_name,
              "middle_name": person.middle_name,
              "gender": person.gender,
              "occupation": '',
              "cellphone_number": '',
              "home_village": person.home_village,
              "home_ta": person.home_ta,
              "home_district": person.home_district,
              "ancestry_village": person.ancestry_village,
              "ancestry_ta": person.ancestry_ta,
              "ancestry_district": person.ancestry_district,
              "birthdate": person.birthdate,
              "birthdate_estimated": person.birthdate_estimated,
              "person_uuid": person.person_uuid,
              "npid": person.npid,
              "date_registered": person.date_registered,
              "last_edited": person.last_edited,
              "location_created_at": person.location_created_at,
              "location_updated_at": person.location_updated_at,
              "creator": person.creator
            }
end


def main
  if File.exists?("/tmp/dde_sync.lock")
    puts 'Another process running!'
    exit
  else
    FileUtils.touch "/tmp/dde_sync.lock"
  end

	pull_records
  push_records
  pull_npids

  ensure
  if File.exists?("/tmp/dde_sync.lock")
    FileUtils.rm "/tmp/dde_sync.lock"
  end
end

main
