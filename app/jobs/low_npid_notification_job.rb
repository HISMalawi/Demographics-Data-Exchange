class LowNpidNotificationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Fetch all sites at once to ensure complete grouping
    sites = fetch_all_sites
  
    # Group sites by district
    grouped_sites = sites.group_by { |site| site[:district_id] }
  
    # Send one email per district
    grouped_sites.each_value do |district_sites|
      district_data = {
        name: district_sites.first[:district_name],
        sites: district_sites
      }
  
      LowNpidNotificationMailer.low_npid(district_data).deliver_later
    end
  end
  
  private
  
  def fetch_all_sites
    query = <<-SQL
      SELECT
        l.name AS location_name,
        ln.location_id,
        l.district_id,
        d.name as district_name,
        COUNT(CASE WHEN assigned = false THEN 1 ELSE NULL END) AS unassigned,
        COUNT(CASE WHEN assigned = true THEN 1 ELSE NULL END) AS assigned,
        ROUND(
          COUNT(CASE WHEN assigned = true THEN 1 ELSE NULL END) / 
          NULLIF(DATEDIFF(MAX(ln.updated_at), MIN(ln.updated_at)), 0), 2
        ) AS avg_consumption_rate_per_day,
        CASE 
          WHEN ROUND(
            COUNT(CASE WHEN assigned = true THEN 1 ELSE NULL END) / 
            NULLIF(DATEDIFF(MAX(ln.updated_at), MIN(ln.updated_at)), 0), 2
          ) = 0 
          THEN COUNT(CASE WHEN assigned = false THEN 1 ELSE NULL END)
          ELSE COUNT(CASE WHEN assigned = false THEN 1 ELSE NULL END) / 
               ROUND(
                 COUNT(CASE WHEN assigned = true THEN 1 ELSE NULL END) / 
                 NULLIF(DATEDIFF(MAX(ln.updated_at), MIN(ln.updated_at)), 0), 2
               )
        END AS days_remaining
      FROM 
        location_npids ln
      JOIN 
        locations l ON ln.location_id = l.location_id
      JOIN
        districts d ON d.district_id = l.district_id 
      GROUP BY 
        ln.location_id, l.name, l.district_id, d.name
      HAVING 
        days_remaining < 30 OR unassigned < 1000
      ORDER BY 
        days_remaining ASC  -- Prioritize urgent ones first
    SQL
  
    ActiveRecord::Base.connection.select_all(query).map(&:symbolize_keys)
  end

end
