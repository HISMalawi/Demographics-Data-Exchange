module LastSeenLastSyncService
    require 'dashboard_service'
    
    def self.processed_data
        begin
            sites = DashboardService.site_activities
            last_activity_grouped = {}
            last_seen_grouped = {}
      
            # Global totals
            total_last_seen_sites = 0
            total_last_synced_sites = 0
            total_sites = 0
    
            sites = sites.select { |entry| entry["activated"] == 1 }
      
            sites.each do |site|
              district_id = site['district_id']
              name = site['district_name']
      
              # Count the total sites (sum of all sites across all districts)
              total_sites += 1
      
              if site['days_since_last_activity'].to_i > 3
                total_last_synced_sites += 1
      
                last_activity_grouped[district_id] ||= {
                  district_id: district_id,
                  name: name,
                  sites_last_activity_greater_than_3_days_sites: 0,
                  sites: [],
                  total_sites: 0 # placeholder
                }
      
                last_activity_grouped[district_id][:sites_last_activity_greater_than_3_days_sites] += 1
                last_activity_grouped[district_id][:sites] << site
              end
      
              if site['days_since_last_seen'].to_i > 3
                total_last_seen_sites += 1
      
                last_seen_grouped[district_id] ||= {
                  district_id: district_id,
                  name: name,
                  sites_last_seen_greater_than_3_days_sites: 0,
                  sites: [],
                  total_sites: 0 # placeholder
                }
      
                last_seen_grouped[district_id][:sites_last_seen_greater_than_3_days_sites] += 1
                last_seen_grouped[district_id][:sites] << site
              end
            end
      
            # Add total sites per district based on district_id
            last_activity_grouped.each do |district_id, data|
              data[:total_sites] = sites.count { |s| s['district_id'] == district_id }
            end
      
            last_seen_grouped.each do |district_id, data|
              data[:total_sites] = sites.count { |s| s['district_id'] == district_id }
            end
      
            # Final JSON-ready arrays sorted alphabetically by district name
            sorted_activity = last_activity_grouped.values.sort_by { |d| d[:name] }
            sorted_last_seen = last_seen_grouped.values.sort_by { |d| d[:name] }
      
            result = {
              last_seen: {
                total_sites: total_sites,
                total_sites_with_issue: total_last_seen_sites,
                districts: sorted_last_seen,
              },
              last_activity: {
                total_sites: total_sites,
                total_sites_with_issue: total_last_synced_sites,
                districts: sorted_activity
              },
             
            }
      
            result
        ensure
            ActiveRecord::Base.connection_pool.release_connection
        end   
    end

end