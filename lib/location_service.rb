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
        name: location.name,
        doc_id: location.couchdb_location_id,
        latitude: location.latitude,
        longitude: location.longitude,
        code: location.code,
        location_tags: location_tags.map(&:name),
      }
    end

    return locations
  end

  def self.find_location(location_id)
    check_replication_status = RestClient.get("pach:pachccc123@localhost:5984/_active_tasks")
    rep_status = JSON.parse(check_replication_status)
    status = 'OFFLINE'
  
    query = Location.where(couchdb_location_id: location_id)
    if query.blank?
      return {}
    end
    location = []
    (query || []).each do |l|
      location_tags = LocationTag.where("l.couchdb_location_id = ?",
                          l.couchdb_location_id).joins("INNER JOIN location_tag_maps m
        ON m.location_tag_id = location_tags.location_tag_id
        INNER JOIN locations l ON l.location_id = m.location_id").select("location_tags.*")
      ds = DistrictSite.where(site_id: l.location_id).first #rescue "Unknown"
      district = Location.find(ds.district_id).name rescue "Unknown"
      
      rd = RegionDistrict.where(district_id: ds.district_id).first
      region = Region.find(rd.region_id).name rescue "Unknown"
    
      ## Check replication status for this site.
      ( rep_status || [] ).each do |s|
        next unless s['source'].match(/#{l.ip_address}/)
        status = 'ONLINE' unless l.ip_address.blank?
      end

      location << {
        name: l.name,
        doc_id: l.couchdb_location_id,
        latitude: l.latitude,
        longitude: l.longitude,
        code: l.code,
        location_tags: location_tags.map(&:name),
        district: district,
        region: region,
        host: l.ip_address,
        sync_status: status
      }
    end
    return location
  end

  def self.get_locations(params)
    name = params[:name]

    # Build Location query
    if name.blank?
      query = Location
    else
      query = Location.where("name like (?)", "#{name}%")
    end

    page_size = (params[:page_size] or DEFAULT_PAGE_SIZE).to_i

    if params.has_key? :page
      offset = (params[:page] or 0).to_i * page_size
      query = query.offset(offset)
    end

    query = query.limit(page_size).order("name ASC")

    locations = []

    (query || []).each do |l|
      location_tags = LocationTag.where("l.couchdb_location_id = ?",
                                        l.couchdb_location_id).joins("INNER JOIN location_tag_maps m
        ON m.location_tag_id = location_tags.location_tag_id
        INNER JOIN locations l ON l.location_id = m.location_id").select("location_tags.*")

      locations << {
        name: l.name,
        doc_id: l.couchdb_location_id,
        latitude: l.latitude,
        longitude: l.longitude,
        code: l.code,
        location_tags: location_tags.map(&:name),
      }
    end

    return locations
  end
  
  def self.get_regions
    regions = []
    ( Region.all || [] ).each do |r|
      sites = []
      allocated_ids = 0
      assigned_ids = 0
      districts = RegionDistrict.where(region_id: r.id)
      
      ( districts || [] ).each do |d|
        ds = DistrictSite.where(district_id: d.id)

        ( ds || [] ).each do |s|
          sites << s.site_id
          total_ids = LocationNpid.where(location_id: s.site_id).count
          total_assigned = LocationNpid.where(["location_id = ? and assigned = 1", s.site_id]).count 
          allocated_ids += total_ids.to_i
          assigned_ids += total_assigned.to_i
        end

      end

      regions << {
        name: r.name,
        sites: sites,
        allocated: allocated_ids,
        assigned: assigned_ids
      }
    end
    
    return regions

  end

  def self.fetch_regional_stats
    @stats = {}
    ( Region.all || [] ).each do |r|
      region_name = r.name.downcase
      @stats["#{region_name}"] = {}
      districts = RegionDistrict.where(region_id: r.id)
      
      ( districts || [] ).each do |d|
        district_sites = 0
        allocated_ids = 0
        assigned_ids = 0
        district = Location.where(location_id: d.id).first
        @stats["#{region_name}"]["#{district.name}"] = {}
        
        ( DistrictSite.where(district_id: d.id) || [] ).each do |s|
          site = Location.where(location_id: s.site_id).first
          #sites << s.site_id
          total_ids = LocationNpid.where(location_id: s.site_id).count
          total_assigned = LocationNpid.where(["location_id = ? and assigned = 1", s.site_id]).count 
          allocated_ids += total_ids.to_i
          assigned_ids += total_assigned.to_i
          district_sites += 1
        end

        @stats["#{region_name}"]["#{district.name}"] = {
          sites: district_sites,
          allocated: allocated_ids,
          assigned: assigned_ids
        }

      end
    end
    return @stats
  end

  private

  DEFAULT_PAGE_SIZE = 10
end
