module LocationService
  
  def self.get_locations
    assigned_sites = LocationNpid.group("couchdb_location_id")
    locations = []
    
    (assigned_sites || []).each do |l|
      location = Location.find_by_couchdb_location_id(l.couchdb_location_id)
      location_tags = LocationTag.where("l.couchdb_location_id = ?",
        l.couchdb_location_id).joins("INNER JOIN location_tag_maps m
        ON m.location_tag_id = location_tags.location_tag_id
        INNER JOIN locations l ON l.location_id = m.location_id").select("location_tags.*")
      
      locations << {
        name:           location.name,
        doc_id:         location.couchdb_location_id,
        latitude:       location.latitude,
        longitude:      location.longitude,
        code:           location.code,
        location_tags:  location_tags.map(&:name)
       }
    end
    
    return locations
    
  end
  
end