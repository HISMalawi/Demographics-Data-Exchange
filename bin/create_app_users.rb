require "csv"
require 'json'

host = "localhost"
port = 1500

#Get token
	token = `curl -X POST "#{host}:#{port}/v1/login" -H "Content-Type: application/json" -d '{"username": "admin", "password": "bht.dde3!"}'`
	token = JSON.parse(token)
	token = token['access_token']


CSV.foreach("/home/fchiyenda/Documents/npid_allocation.csv", headers: true, encoding: 'ISO-8859-1') do |row|
	next if row[3].blank?


	#Get site location_id
	location = Location.where(location_id: row[3])
    couchdb_location_id = location.first.couchdb_location_id

    #set user credentials
	anc_user 	= row[8]
	anc_pwd  	= row[9]
	opd_user 	= row[10]
	opd_pwd  	= row[11]
	hts_user 	= row[12]
	hts_pwd  	= row[13]
	lims_user 	= row[14]
	lims_pwd  	= row[15]
	mat_user  	= row[16]
	mat_pwd		= row[17]

	puts "Adding users for #{row[2]}"

	puts "Adding ANC User #{row[2]}"

	response = `curl -X POST "#{host}:#{port}/v1/add_user" -H "Content-Type: application/json" -H "Authorization: token #{token}" -d '{"username": "#{anc_user}","password":"#{anc_pwd}", "location":"#{couchdb_location_id}"}'`
    
   
    response = JSON.parse(response) 

    raise 	.inspect

	if response.status = 200

		puts "Adding OPD User for #{row[2]}"

		response= `curl -X POST "#{host}:#{port}/v1/add_user" -H "Content-Type: application/json" -H "Authorization: token #{token}" -d '{"username": "#{opd_user}","password":"#{opd_pwd}", "location":"#{couchdb_location_id}"}'`

		response = JSON.parse(response) 
	else
		puts "Something went wrong"
		exit
    end



    if response.status = 200

		puts "Adding HTS User for #{row[2]}"

		response = `curl -X POST "#{host}:#{port}/v1/add_user" -H "Content-Type: application/json" -H "Authorization: token #{token}" -d '{"username": "#{hts_user}","password":"#{hts_pwd}", "location":"#{couchdb_location_id}"}'`

		response = JSON.parse(response) 
	else
		puts "Something went wrong"
		exit
    end

    if response.status = 200
	    puts "Adding LIMS User for #{row[2]}"

		response = `curl -X POST "#{host}:#{port}/v1/add_user" -H "Content-Type: application/json" -H "Authorization: token #{token}" -d '{"username": "#{lims_user}","password":"#{lims_pwd}", "location":"#{couchdb_location_id}"}'`

		response = JSON.parse(response) 
	else
		puts "Something went wrong"
		exit
    end

    if response.status = 200

		puts "Adding MAT User for #{row[2]}"

		response = `curl -X POST "#{host}:#{port}/v1/add_user" -H "Content-Type: application/json" -H "Authorization: token #{token}" -d '{"username": "#{mat_user}","password":"#{mat_pwd}", "location":"#{couchdb_location_id}"}'`

		response = JSON.parse(response) 
	    else
			puts "Something went wrong"
			exit
	    end

end

puts "Completed!"