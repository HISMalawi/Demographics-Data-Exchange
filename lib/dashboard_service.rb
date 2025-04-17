module DashboardService

  def self.new_reg_by_site
    PersonDetail.joins("JOIN locations l ON person_details.location_created_at = l.location_id").where('date_registered BETWEEN ? AND ?',
      Date.today.strftime('%Y-%m-%d %H:%M:%S'),Date.today.strftime('%Y-%m-%d') + ' 23:59:59').group(:name).count
  end

  def self.new_reg_past_30
    result = PersonDetail.find_by_sql('SELECT l.name,date(date_registered),count(*) registrations from person_details pd
      JOIN locations l
      ON pd.location_created_at = l.location_id
      WHERE date_registered >= DATE_SUB(date(now()), INTERVAL 30 DAY)
      AND activated = true
      GROUP BY l.name,date(date_registered)')

    result.group_by{ |site| site[:name] }
  end

  def self.client_movements
    sites = FootPrint.find_by_sql('SELECT sites_visited, count(*) number_of_pple FROM (SELECT person_uuid, count(*) as sites_visited
      FROM (SELECT DISTINCT person_uuid,location_id FROM foot_prints fp
      group by person_uuid,location_id) movement group by person_uuid) sites
      GROUP BY sites_visited;')
  end

  def self.npids
    assigned_unassiged_npids = ActiveRecord::Base.connection.select_all("
      SELECT l.name location_name, ln.location_id, l.activated,
      count(if(assigned = false,1,null)) unassigned,
      count(if(assigned = true,1,null)) assigned,
      max(ln.updated_at) date_last_updated,
      ROUND(count(if(assigned = true,1,null))/(DATEDIFF(max(date(ln.updated_at)),min(date(ln.updated_at))))) avg_consumption_rate_per_day
      FROM location_npids ln
      JOIN locations l
      ON ln.location_id = l.location_id
      WHERE l.ip_address is not null
      GROUP BY ln.location_id,l.name, l.activated
      ORDER BY max(ln.updated_at) desc,count(*);
      ")
  end

  def self.location_npids(location_id)
    assigned_unassiged_npids = ActiveRecord::Base.connection.select_all("
      SELECT l.name location_name, ln.location_id,
      count(if(assigned = false,1,null)) unassigned,
      count(if(assigned = true,1,null)) assigned,
      count(if(allocated = true OR assigned = true,1,null)) allocated,
      count(if(allocated = false AND assigned = false,1,null)) unallocated,
      max(ln.updated_at) date_last_updated,
      ROUND(count(if(assigned = true,1,null))/(DATEDIFF(max(date(ln.updated_at)),min(date(ln.updated_at))))) avg_consumption_rate_per_day
      FROM location_npids ln
      JOIN locations l
      ON ln.location_id = l.location_id
      WHERE l.location_id = #{location_id}
      GROUP BY ln.location_id,l.name
      ORDER BY max(ln.updated_at) desc,count(*);
      ")
  end


  def self.connected_sites
    connected_sites = Location.where('ip_address is not null').select(:location_id, :name, :ip_address, :creator, :created_at, :updated_at, :last_seen, :activated)
    reachable_sites = ''

    ping_tested_sites = Parallel.map(connected_sites, in_threads: connected_sites.size.to_i) do |site|
      check = Net::Ping::External.new(site.ip_address)
       #Add site to update list if it is reachable
       created_at = site.created_at.to_datetime.strftime('%Y-%m-%d %H:%M:%S') unless site.created_at.blank?
       updated_at = site.updated_at.to_datetime.strftime('%Y-%m-%d %H:%M:%S') unless site.updated_at.blank?

       reachable = false

       if check.ping?
        last_seen = Time.now.to_datetime.strftime('%Y-%m-%d %H:%M:%S')
        reachable_sites += " (#{site.location_id}, \"#{site.name}\", #{site.creator}, \"#{created_at}\", \"#{updated_at}\", \"#{last_seen}\"), "
        reachable = true
       end
       {site: site.name, reacheable: reachable, activated: site.activated}
    end

    unless reachable_sites.blank?
      reachable_sites.prepend('INSERT into `locations` (location_id, name, creator, created_at, updated_at, last_seen) VALUES ')
      reachable_sites.chop!.chop!
      reachable_sites += ' ON DUPLICATE KEY UPDATE last_seen = VALUES(last_seen);'
      ActiveRecord::Base.connection.execute(reachable_sites)
    end
    return ping_tested_sites
  end

  def self.site_activities
    site_activity = ActiveRecord::Base.connection.select_all("
      SELECT l.name site_name, 
      l.location_id,
      d.name as district_name,
      l.ip_address,
      max(fp.created_at) last_activity,
      l.last_seen last_seen,
      l.activated,
      l.district_id,
      TIMESTAMPDIFF(DAY, max(fp.created_at), CURRENT_TIMESTAMP()) days_since_last_activity,
      TIMESTAMPDIFF(DAY, l.last_seen, CURRENT_TIMESTAMP()) days_since_last_seen
      FROM locations l
      JOIN districts d ON d.district_id = l.district_id
      LEFT JOIN foot_prints fp
      ON fp.location_id = l.location_id
      WHERE l.ip_address is not null
      GROUP BY l.name, l.last_seen, l.activated, l.location_id;")
  end
end
