class LastSeenMailerPreview < ActionMailer::Preview
    def summary_of_last_seen
        begin 
            sites = DashboardService.site_activities
            last_activity_grouped = {}
            last_seen_grouped = {}
            
            # Global totals
            total_last_seen_sites = 0
            total_last_synced_sites = 0
            
            sites.each do |site|
                district_id = site['district_id']
                name = site['district_name']
            
                if site['days_since_last_activity'].to_i > 3 && site['days_since_last_seen'].to_i == 0
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
            
            # Example payloads (optional: return or use in your views/API)
            result = {
                last_seen: {
                total_sites_with_issue: total_last_seen_sites,
                districts: sorted_last_seen
                },
                last_activity: {
                total_sites_with_issue: total_last_synced_sites,
                districts: sorted_activity
                }
            }
            
            # Send summary emails

            #LastSyncedMailer.last_synced_more_than_3_days(result[:last_activity][:districts]).deliver_now if result[:last_activity][:districts].any?
            LastSeenMailer.summary_of_last_seen(result[:last_seen]).deliver_now if result[:last_seen][:districts].any?
            
        ensure
           ActiveRecord::Base.connection_pool.release_connection
        end
    end
end