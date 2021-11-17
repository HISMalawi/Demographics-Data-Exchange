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
    assigned_unassiged_npids = LocationNpid.all.group(:location_id, :assigned)

    averaged_consumption_rate =

  end
end
