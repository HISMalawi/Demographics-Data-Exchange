class CouchdbLocationTagMap < CouchRest::Model::Base
	property				:location_id,							String
	property				:location_tag_id,					String

	timestamps!
end
