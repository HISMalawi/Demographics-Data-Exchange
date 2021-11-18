module DashboardService

  def self.new_reg_by_site
    PersonDetail.joins("JOIN locations l ON person_details.location_created_at = l.location_id").where("date(date_registered) = date(now())").group(:name).count
  end

  def self.new_reg_past_30
    result = PersonDetail.find_by_sql('SELECT l.name,date(date_registered),count(*) registrations from person_details pd
      JOIN locations l
      ON pd.location_created_at = l.location_id
      WHERE date(date_registered) >= DATE_SUB(date(now()), INTERVAL 30 DAY)
      GROUP BY date(date_registered)
      ORDER BY date(date_registered) desc;')


    result.group_by{ |site| site[:name] }
  end

  def self.client_movements
    sites = FootPrint.find_by_sql('SELECT sites_visited, count(*) number_of_pple FROM (SELECT person_uuid, count(*) as sites_visited FROM (SELECT DISTINCT person_uuid,location_id FROM foot_prints fp
      group by person_uuid,location_id) movement group by person_uuid) sites
      GROUP BY sites_visited;')
  end

  def self.npids
    assigned_unassiged_npids = ActiveRecord::Base.connection.select_all("
      SELECT l.name location_name, ln.location_id,
      count(if(assigned = false,1,null)) unassigned,
      count(if(assigned = true,1,null)) assigned,
      max(ln.updated_at) date_last_updated,
      ROUND(count(if(assigned = true,1,null))/(DATEDIFF(max(date(ln.updated_at)),min(date(ln.updated_at))))) avg_consumption_rate_per_day
      FROM location_npids ln
      JOIN locations l
      ON ln.location_id = l.location_id
      WHERE l.ip_address is not null
      GROUP BY ln.location_id,l.name
      ORDER BY max(ln.updated_at) desc,count(*);
      ")
  end

  def self.connected_sites
    connected_sites = Location.where('ip_address is not null').select(:name, :ip_address)

    ping_tested_sites = Parallel.map(connected_sites) do |site|
      check = Net::Ping::External.new(site.ip_address)
      {site: site.name, reacheable: check.ping?}
    end
  end
end
