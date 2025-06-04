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
    sites = FootPrint.find_by_sql('SELECT
        COUNT(*) AS number_of_pple,
        sites_visited
      FROM
        (
        SELECT
          COUNT(DISTINCT location_id) AS sites_visited
        FROM
          foot_prints
        GROUP BY
          person_uuid
      ) AS person_sites
      GROUP BY
        sites_visited;')
  end

  def self.npids
    ActiveRecord::Base.connection.select_all("
      SELECT
      l.name location_name,
      l.location_id,
      l.activated,
      assigned.assigned,
      unassigned.unassigned,
      date_last_updated,
      ROUND(assigned.assigned / DATEDIFF(date_last_updated, min_date_updated)) avg_consumption_rate_per_day
    FROM
      locations l
    JOIN (
      SELECT
        location_id,
        max(updated_at) date_last_updated,
        min(updated_at) min_date_updated
      FROM
        location_npids
      GROUP BY
        location_id) max_updated
          ON
      l.location_id = max_updated.location_id
    JOIN (
      SELECT
        ln.location_id,
        count(*) assigned
      FROM
        location_npids ln
      WHERE ln.assigned = 1
      GROUP BY
        location_id) assigned
          ON
      l.location_id = assigned.location_id
    JOIN  (
      SELECT
        ln.location_id,
        count(*) unassigned
      FROM
        location_npids ln
      WHERE ln.assigned = 0
      GROUP BY
        location_id) unassigned
          ON
      l.location_id = unassigned.location_id
    WHERE
      ip_address is not null;
      ")
  end

  def self.location_npids(location_id)
    ActiveRecord::Base.connection.select_all("
      SELECT
      l.name location_name,
      l.location_id,
      l.activated,
      assigned.assigned,
      unassigned.unassigned,
      date_last_updated,
      ROUND(assigned.assigned / DATEDIFF(date_last_updated, min_date_updated)) avg_consumption_rate_per_day
    FROM
      locations l
    JOIN (
      SELECT
        location_id,
        max(updated_at) date_last_updated,
        min(updated_at) min_date_updated
      FROM
        location_npids
      GROUP BY
        location_id) max_updated
          ON
      l.location_id = max_updated.location_id
    JOIN (
      SELECT
        ln.location_id,
        count(*) assigned
      FROM
        location_npids ln
      WHERE ln.assigned = 1
      GROUP BY
        location_id) assigned
          ON
      l.location_id = assigned.location_id
    JOIN  (
      SELECT
        ln.location_id,
        count(*) unassigned
      FROM
        location_npids ln
      WHERE ln.assigned = 0
      GROUP BY
        location_id) unassigned
          ON
      l.location_id = unassigned.location_id
    WHERE
      ip_address is not null;
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
    ActiveRecord::Base.connection.select_all("
      SELECT l.name site_name,
      l.location_id,
      d.name as district_name,
      l.ip_address,
      max_created_at last_activity,
      l.last_seen last_seen,
      l.activated,
      l.district_id,
      TIMESTAMPDIFF(DAY, max_created_at, CURRENT_TIMESTAMP()) days_since_last_activity,
      TIMESTAMPDIFF(DAY, l.last_seen, CURRENT_TIMESTAMP()) days_since_last_seen
      FROM locations l
      LEFT JOIN (SELECT location_id, max(fp.created_at) max_created_at FROM foot_prints fp
			group by location_id) max_created
		  ON l.location_id = max_created.location_id 
      JOIN districts d ON l.district_id = d.district_id
      WHERE l.ip_address is not null
      GROUP BY l.activated, l.location_id, l.name, l.last_seen
      ORDER by l.name;")
  end
end
