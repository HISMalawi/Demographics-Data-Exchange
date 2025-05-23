module LowNpidNotificationService
    
    def self.processed_data
        sites = fetch_all_sites

        #Global Totals
        total_sites = 0 

        # Ensure BigDecimal values are converted to Float
        sites.each do |site|
        site[:avg_consumption_rate_per_day] = site[:avg_consumption_rate_per_day].to_f if site[:avg_consumption_rate_per_day].is_a?(BigDecimal)
        site[:days_remaining] = site[:days_remaining].to_f if site[:days_remaining].is_a?(BigDecimal)
        end

        # Group by district
        grouped_sites = sites.group_by { |site| site[:district_id] }

        # Build structured district list
        districts = grouped_sites.map do |district_id, district_sites|
        {
            district_id: district_id,
            name: district_sites.first[:district_name],
            sites: district_sites
        }
        end

        # Sort alphabetically by district name
        sorted_districts = districts.sort_by { |d| d[:name] }

        result = {
        total_sites: sites.count,
        districts: sorted_districts
        }

       result
    end 

    private
    def self.fetch_all_sites
        query = <<-SQL
        SELECT
            l.name AS location_name,
            ln.location_id,
            l.district_id,
            l.ip_address,
            l.activated,
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
            activated = true and days_remaining < 30 OR unassigned < 1000
        ORDER BY 
            days_remaining ASC
        SQL

        ActiveRecord::Base.connection.select_all(query).map(&:symbolize_keys)
    end
end 