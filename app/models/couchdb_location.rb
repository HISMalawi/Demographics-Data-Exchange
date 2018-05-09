class CouchdbLocation < CouchRest::Model::Base
	property				:name,							String
	property				:description,				String
	property				:latitude,					String
	property				:longitude,					String
	property				:voided,						String
	property				:parent_location,		String
	property				:code,							String
	property				:creator,						String

	timestamps!
end
