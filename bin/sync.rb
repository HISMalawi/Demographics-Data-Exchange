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


def push_records
  update_url = "http://#{@host}:#{@port}/api/v1/person_details"
  create_url = "http://#{@host}:#{@port}/api/v1/person_details"

	push_seq = Config.find_by_config('push_seq')['config_value'].to_i

	update_records = PersonDetail.where('person_details.id > ? AND person_details.location_updated_at = ?', push_seq,@location ).joins(:person_details_audit)

  new_records = PersonDetail.where('person_uuid not IN (?) AND person_details.id > ? AND person_details.location_updated_at = ?', (PersonDetail.where('person_details.id > ? AND person_details.location_updated_at = ?', push_seq,@location ).joins(:person_details_audit).select('person_details.person_uuid')), push_seq, @location)
  
  #PUSH UPDATES
  update_records.each do | record |
    debugger
    response = JSON.parse(RestClient.put(update_url,record.to_json,{content_type: :json, accept: :json}, headers={Authorization: authenticate }))

  end

end


def main
	pull_records
end

main