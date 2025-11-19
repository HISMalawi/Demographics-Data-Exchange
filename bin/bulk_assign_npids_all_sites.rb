
require 'rest-client'

puts 'Enter dde ip or host'
dde_ip = gets.chomp
puts 'Enter dde port'
dde_port = gets.chomp

url = "http://#{dde_ip}:#{dde_port}"
puts 'please enter username for dde master'
username = gets.chomp
puts 'please enter password for dde master'
password = gets.chomp
puts 'Please enter the number of batch ids you would like to assign'
batch_ids = gets.chomp.to_i


locations = Location.where('ip_address is not null')
count = locations.count
locations.each_with_index do | location, i |
    unassigned_npids = LocationNpid.where(location_id: location.location_id, assigned: false).count
    npid_balance = batch_ids - unassigned_npids

    if npid_balance > 0
        token = JSON.parse(RestClient.post(url + '/v1/login', {username: username, password: password}.to_json, {content_type: :json, accept: :json}))
        assign_url = "#{url}/v1/assign_npids"
        puts "Performing operation #{i} / #{count} assigning #{npid_balance} npids to #{location.name}"
        response = JSON.parse(RestClient.post(assign_url,{limit: npid_balance, location_id: location.location_id}.as_json,headers={Authorization: token['access_token']}))
    end
end