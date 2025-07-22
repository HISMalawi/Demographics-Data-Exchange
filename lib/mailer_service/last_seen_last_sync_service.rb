module LastSeenLastSyncService
  require 'dashboard_service'

  def self.processed_data
    begin
      sites = DashboardService.site_activities

      stats = calculate_stats(sites)

      # Save the raw sites, not the processed stats
      save_stats_to_cache(sites)

      yesterday_sites = fetch_yesterday_stats
 
      if yesterday_sites.is_a?(Array)
        yesterday_stats = calculate_stats(yesterday_sites)
        stats[:comparison] = compare_stats(stats, yesterday_stats)
      elsif yesterday_sites.is_a?(Hash) && yesterday_sites[:last_seen] && yesterday_sites[:last_seen][:districts]
        # Already in stats format (for backward compatibility or manual test)
        stats[:comparison] = compare_stats(stats, yesterday_sites)
      end

      stats
    ensure
      ActiveRecord::Base.connection_pool.release_connection
    end
  end

  private

  def self.calculate_stats(sites)
    last_activity_grouped = {}
    last_seen_grouped = {}
    total_last_seen_sites = 0
    total_last_synced_sites = 0
    total_sites = 0

    # Only look at sites that are activated (ignore the rest)
    sites = sites.select { |entry| entry["activated"] == 1 }

    # Group by region, then by district
    sites.each do |site|
      region_id = site['region_id']
      region_name = site['region_name']
      district_id = site['district_id']
      district_name = site['district_name']
      total_sites += 1

      # Last activity grouping
      if site['days_since_last_activity'].to_i > 3 && site['days_since_last_seen'].to_i < 3
        total_last_synced_sites += 1
        last_activity_grouped[region_id] ||= { region_id: region_id, name: region_name, total_sites: 0, total_sites_with_issue: 0, districts: {} }
        last_activity_grouped[region_id][:districts][district_id] ||= {
          district_id: district_id,
          name: district_name,
          sites_last_activity_greater_than_3_days_sites: 0,
          sites: [],
          total_sites: 0
        }
        last_activity_grouped[region_id][:districts][district_id][:sites_last_activity_greater_than_3_days_sites] += 1
        last_activity_grouped[region_id][:districts][district_id][:sites] << site
      end

      # Last seen grouping
      if site['days_since_last_seen'].to_i > 3
        total_last_seen_sites += 1
        last_seen_grouped[region_id] ||= { region_id: region_id, name: region_name, total_sites: 0, total_sites_with_issue: 0, districts: {} }
        last_seen_grouped[region_id][:districts][district_id] ||= {
          district_id: district_id,
          name: district_name,
          sites_last_seen_greater_than_3_days_sites: 0,
          sites: [],
          total_sites: 0
        }
        last_seen_grouped[region_id][:districts][district_id][:sites_last_seen_greater_than_3_days_sites] += 1
        last_seen_grouped[region_id][:districts][district_id][:sites] << site
      end
    end

    # Initialize region counts for all regions that have sites
    sites.group_by { |s| s['region_id'] }.each do |region_id, region_sites|
      region_name = region_sites.first['region_name']
      
      # Initialize last_activity_grouped for this region if it doesn't exist
      last_activity_grouped[region_id] ||= { 
        region_id: region_id, 
        name: region_name, 
        total_sites: 0, 
        total_sites_with_issue: 0, 
        districts: {} 
      }
      
      # Initialize last_seen_grouped for this region if it doesn't exist
      last_seen_grouped[region_id] ||= { 
        region_id: region_id, 
        name: region_name, 
        total_sites: 0, 
        total_sites_with_issue: 0, 
        districts: {} 
      }
    end

    # Count total sites per region and district for last_activity
    last_activity_grouped.each do |region_id, region|
      region[:total_sites] = 0
      region[:total_sites_with_issue] = 0
      
      region[:districts].each do |district_id, district|
        district[:total_sites] = sites.count { |s| s['district_id'] == district_id }
        region[:total_sites_with_issue] += district[:sites_last_activity_greater_than_3_days_sites]
        region[:total_sites] += district[:total_sites]
      end
      
      # If region has no districts with issues, still count total sites in region
      if region[:districts].empty?
        region[:total_sites] = sites.count { |s| s['region_id'] == region_id }
      end
      
      region[:districts] = region[:districts].values.sort_by { |d| d[:name] }
    end

    # Count total sites per region and district for last_seen
    last_seen_grouped.each do |region_id, region|
      region[:total_sites] = 0
      region[:total_sites_with_issue] = 0
      
      region[:districts].each do |district_id, district|
        district[:total_sites] = sites.count { |s| s['district_id'] == district_id }
        region[:total_sites_with_issue] += district[:sites_last_seen_greater_than_3_days_sites]
        region[:total_sites] += district[:total_sites]
      end
      
      # If region has no districts with issues, still count total sites in region
      if region[:districts].empty?
        region[:total_sites] = sites.count { |s| s['region_id'] == region_id }
      end
      
      region[:districts] = region[:districts].values.sort_by { |d| d[:name] }
    end

    sorted_activity = last_activity_grouped.values.sort_by { |r| r[:name] }
    sorted_last_seen = last_seen_grouped.values.sort_by { |r| r[:name] }

    stats = {
      last_seen: {
        total_sites: total_sites,
        total_sites_with_issue: total_last_seen_sites,
        regions: sorted_last_seen,
      },
      last_activity: {
        total_sites: total_sites,
        total_sites_with_issue: total_last_synced_sites,
        regions: sorted_activity
      }
    }


    stats
  end

  def self.save_stats_to_cache(sites)
    # Only one entry per calendar date for the given stat name, using app timezone
    range = Time.zone.today.beginning_of_day..Time.zone.today.end_of_day
  
    stat = SyncStatsCache.where(name: 'last_seen_and_last_sync', created_at: range).order(created_at: :desc).first
    if stat
      stat.update!(value: sites.to_json)
    else
      SyncStatsCache.create!(
        name: 'last_seen_and_last_sync',
        value: sites.to_json,
      )
    end
  end

  def self.fetch_yesterday_stats
    yesterday_cache = SyncStatsCache.where(name: 'last_seen_and_last_sync')
      .where('created_at < ?', Time.now.beginning_of_day)
      .order(created_at: :desc).first
    yesterday_cache ? JSON.parse(yesterday_cache.value) : nil
  end

  def self.compare_stats(today_stats, yesterday_data)
    # Compare for last_seen
    (today_stats[:last_seen][:regions] || []).each do |region|
      yest_region = (yesterday_data[:last_seen][:regions] || []).find { |r| r[:region_id] == region[:region_id] } rescue nil
      region[:districts].each do |district|
        yest_district = yest_region ? (yest_region[:districts] || []).find { |d| d[:district_id] == district[:district_id] } : nil
        today_count = district[:sites_last_seen_greater_than_3_days_sites]
        yest_count = yest_district ? yest_district[:sites_last_seen_greater_than_3_days_sites] : 0
        change = today_count - yest_count
        change_percent =
          if yest_count == 0
            today_count == 0 ? 0 : 100
          elsif change == 0
            0
          else
            ((change.to_f / yest_count) * 100).round(2)
          end
        district[:yesterday] = yest_count
        district[:change] = change
        district[:change_percent] = change_percent
      end
    end

    # Compare for last_activity
    (today_stats[:last_activity][:regions] || []).each do |region|
      yest_region = (yesterday_data[:last_activity][:regions] || []).find { |r| r[:region_id] == region[:region_id] } rescue nil
      region[:districts].each do |district|
        yest_district = yest_region ? (yest_region[:districts] || []).find { |d| d[:district_id] == district[:district_id] } : nil
        today_count = district[:sites_last_activity_greater_than_3_days_sites]
        yest_count = yest_district ? yest_district[:sites_last_activity_greater_than_3_days_sites] : 0
        change = today_count - yest_count
        change_percent =
          if yest_count == 0
            today_count == 0 ? 0 : 100
          elsif change == 0
            0
          else
            ((change.to_f / yest_count) * 100).round(2)
          end
        district[:yesterday] = yest_count
        district[:change] = change
        district[:change_percent] = change_percent
      end
    end
    nil
  end

  def self.add_comparison_to_districts(today_districts, yesterday_districts, key)
    today_districts.each do |district|
      yest_d = yesterday_districts[district[:district_id]]
      today_count = district[key]
      yest_count = yest_d ? yest_d[key] : 0
      change = today_count - yest_count
      change_percent =
        if yest_count == 0
          today_count == 0 ? 0 : 100
        elsif change == 0
          0
        else
          ((change.to_f / yest_count) * 100).round(2)
        end
      district[:yesterday] = yest_count
      district[:change] = change
      district[:change_percent] = change_percent
    end
  end
end