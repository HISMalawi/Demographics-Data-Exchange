class LowNpidNotificationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
    
    site = ActiveRecord::Base.connection.select_all("SELECT	
          l.name location_name,
          ln.location_id,
          count(if(assigned = false, 1, null)) unassigned,
          count(if(assigned = true, 1, null)) assigned,
          (ROUND(count(if(assigned = true, 1, null))/(DATEDIFF(max(date(ln.updated_at)),
           min(date(ln.updated_at)))))) avg_consumption_rate_per_day
        FROM
          location_npids ln
        JOIN locations l
          on ln.location_id = l.location_id
        WHERE
          ln.location_id = #{args[0]}
        GROUP BY location_id;").first.symbolize_keys

      if site[:avg_consumption_rate_per_day].to_i.zero?
        site[:days_remaining] = site[:unassigned]
      else
        site[:days_remaining] = (site[:unassigned] / site[:avg_consumption_rate_per_day])
      end

      if  site[:days_remaining].to_i < 30 || site[:unassigned].to_i < 1_000
           #send notification
           LowNpidNotificationMailer.low_npid(site).deliver_later
      end
  end
end
