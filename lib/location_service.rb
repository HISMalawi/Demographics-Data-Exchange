module LocationService
  
  def self.list_assigned_locations
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

  def self.get_locations(params)
    
    name = params[:name]

    if name.blank?
      location = Location.limit(10).order("name ASC")
    else
      location = Location.where("name like (?)", "#{name}%").order("name ASC")
    end

    (location || []).each do |l|

      location_tags = LocationTag.where("l.couchdb_location_id = ?",
        l.couchdb_location_id).joins("INNER JOIN location_tag_maps m
        ON m.location_tag_id = location_tags.location_tag_id
        INNER JOIN locations l ON l.location_id = m.location_id").select("location_tags.*")

      locations << {
          name:           l.name,
          doc_id:         l.couchdb_location_id,
          latitude:       l.latitude,
          longitude:      l.longitude,
          code:           l.code,
          location_tags:  location_tags.map(&:name)
        }

    end

  end

end