require 'rest-client'

sync_configs = YAML.load(File.read("#{Rails.root}/config/database.yml"))[:dde_sync_config]


@host = sync_configs[:host]
@port = sync_configs[:port]
@username = sync_configs[:username]
@pwd = sync_configs[:host]
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

def pull_new_records
  pull_seq = Config.find_by_config('pull_seq_new')['config_value'].to_i
  url = "http://#{@host}:#{@port}/v1/person_changes_new?site_id=#{@location}&pull_seq=#{pull_seq}"

  updates = JSON.parse(RestClient.get(url,headers={Authorization: authenticate }))

  updates.each do |record|
  	person = PersonDetail.unscoped.find_by(npid: record['npid'],person_uuid: record['person_uuid'])
    pull_seq = record['id'].to_i
    record.delete('id')
    record.delete('created_at')
    record.delete('updated_at')
    ActiveRecord::Base.transaction do
    	if person.blank?
        PersonDetail.create!(record)
    	else
          person.update(record)
          audit_record = JSON.parse(person.to_json)
          audit_record.delete('id')
          audit_record.delete('created_at')
          audit_record.delete('updated_at')
          PersonDetailsAudit.create!(audit_record)
    	end
  	  Config.where(config: 'pull_seq_new').update(config_value: pull_seq)
    end
  end
end

def pull_updated_records
  pull_seq = Config.find_by_config('pull_seq_update')['config_value'].to_i
  url = "http://#{@host}:#{@port}/v1/person_changes_updates?site_id=#{@location}&pull_seq=#{pull_seq}"

  updates = JSON.parse(RestClient.get(url,headers={Authorization: authenticate }))

  updates.each do |record|
    person = PersonDetail.unscoped.find_by(npid: record['npid'],person_uuid: record['person_uuid'])
    pull_seq = record['update_seq'].to_i
    record.delete('id')
    record.delete('created_at')
    record.delete('updated_at')
    record.delete('update_seq')
    ActiveRecord::Base.transaction do
      if person.blank?
        PersonDetail.create!(record)
      else
          person.update(record)
          audit_record = JSON.parse(person.to_json)
          audit_record.delete('id')
          audit_record.delete('created_at')
          audit_record.delete('updated_at')
          audit_record.delete('update_seq')
          PersonDetailsAudit.create!(audit_record)
      end
      Config.where(config: 'pull_seq_update').update(config_value: pull_seq)
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


def push_records_new
  url = "http://#{@host}:#{@port}/v1/push_changes_new"

	push_seq = Config.find_by_config('push_seq_new')['config_value'].to_i

  records_to_push = PersonDetail.unscoped.where('person_details.id > ? AND person_details.location_updated_at = ?', push_seq,@location).order(:id).limit(100)

  #PUSH UPDATES
  records_to_push.each do | record |
    begin
      response = RestClient.post(url,format_payload(record), headers={Authorization: authenticate })
      redo if response.code != 201
      updated = Config.find_by_config('push_seq_new').update(config_value: record.id.to_i) if response.code == 201
      redo if updated != true
    rescue => e
        File.write("#{Rails.root}/log/sync_err.log", e, mode: 'a')
        exit
    end
  end
end

def push_records_updates
  url = "http://#{@host}:#{@port}/v1/push_changes_updates"

  push_seq = Config.find_by_config('push_seq_update')['config_value'].to_i

  records_to_push = PersonDetail.unscoped.joins(:person_details_audit).where('person_details.location_updated_at = ?
      AND person_details_audits.id > ?',@location, push_seq).order('person_details_audits.id').limit(100).select('person_details.*,person_details_audits.id as update_seq')

  #PUSH UPDATES
  records_to_push.each do | record |
    begin
      response = RestClient.post(url,format_payload(record), headers={Authorization: authenticate })
      redo if response.code != 201
      updated = Config.find_by_config('push_seq_update').update(config_value: record.update_seq.to_i) if response.code == 201
      redo if updated != true
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
              "creator": person.creator,
              "voided": person.voided,
              "voided_by": person.voided_by,
              "date_voided": person.date_voided,
              "void_reason": person.void_reason,
              "first_name_soundex": person.first_name_soundex,
              "last_name_soundex": person.last_name_soundex,
              "update_seq": (person.update_seq rescue nil)
            }
end

def push_footprints
  url = "http://#{@host}:#{@port}/v1/push_footprints"

  footprints = FootPrint.where(synced: false)

  footprints.each do |foot|
     response = RestClient.post(url,foot.as_json, headers={Authorization: authenticate })
     foot.update(synced: true) if response.code == 201
  end
end


def main
  if File.exists?("/tmp/dde_sync.lock")
    puts 'Another process running!'
    exit
  else
    FileUtils.touch "/tmp/dde_sync.lock"
  end
  begin
	 pull_new_records
   pull_updated_records
   push_records_new
   push_records_updates
   push_footprints
   pull_npids
  ensure
    if File.exists?("/tmp/dde_sync.lock")
      FileUtils.rm "/tmp/dde_sync.lock"
    end
  end
end

main
