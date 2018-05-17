class CouchdbLocation < CouchRest::Model::Base
	property				:name,							String
	property				:description,				String
	property				:latitude,					String
	property				:longitude,					String
	property				:voided,						String
	property        :void_reason,       String
	property				:parent_location,		String
	property				:code,							String
	property				:creator,						String

	timestamps!

  design do
    view :by_name
  end
  
	def self.get_location_by_name(name)
	  location = CouchdbLocation.find_by_name(name)
	  return location
	end
	
end
