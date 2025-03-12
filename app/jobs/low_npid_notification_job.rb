class LowNpidNotificationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    offset = 0
    batch_size = 10
  
    loop do
      # Fetch only sites that need email notifications
      sites = ActiveRecord::Base.connection.select_all("
        SELECT
          l.name AS location_name,
          ln.location_id,
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
        GROUP BY 
          ln.location_id, l.name
        HAVING 
          days_remaining < 30 OR unassigned < 1000
        ORDER BY 
          days_remaining ASC  -- Prioritize urgent ones first
        LIMIT #{batch_size} OFFSET #{offset}
      ").map(&:symbolize_keys)
  
      # Stop if there are no more results
      break if sites.empty?
  
      # Send notifications
      sites.each do |site|
        LowNpidNotificationMailer.low_npid(site).deliver_later
      end
  
      # Move to the next batch
      offset += batch_size
    end
  end
  
end
