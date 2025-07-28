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
    # Filter only activated sites
    sites = sites.select { |s| s["activated"] == 1 }
    total_sites = sites.size

    # Build grouped data for both last_seen and last_activity
    last_seen_grouped, total_last_seen_sites = build_issue_group(sites, 'days_since_last_seen', 'sites_last_seen_greater_than_3_days_sites') { |s| s.to_i > 3 }
    last_activity_grouped, total_last_synced_sites = build_issue_group(sites, 'days_since_last_activity', 'sites_last_activity_greater_than_3_days_sites') do |val, site|
      val.to_i > 3 && site['days_since_last_seen'].to_i < 3
    end

    # Enrich regions with total site counts and sort
    enrich_regions_with_totals!(last_seen_grouped, sites, 'sites_last_seen_greater_than_3_days_sites')
    enrich_regions_with_totals!(last_activity_grouped, sites, 'sites_last_activity_greater_than_3_days_sites')

    {
      last_seen: {
        total_sites: total_sites,
        total_sites_with_issue: total_last_seen_sites,
        regions: last_seen_grouped.values.sort_by { |r| r[:name] }
      },
      last_activity: {
        total_sites: total_sites,
        total_sites_with_issue: total_last_synced_sites,
        regions: last_activity_grouped.values.sort_by { |r| r[:name] }
      }
    }
  end

  def self.build_issue_group(sites, field_key, counter_key)
    grouped = {}
    total_with_issue = 0

    sites.each do |site|
      value = site[field_key]
      condition_met = block_given? ? yield(value, site) : value.to_i > 3
      next unless condition_met

      total_with_issue += 1
      region_id, region_name = site['region_id'], site['region_name']
      district_id, district_name = site['district_id'], site['district_name']

      grouped[region_id] ||= {
        region_id: region_id, name: region_name,
        total_sites: 0, total_sites_with_issue: 0, districts: {}
      }

      district = grouped[region_id][:districts][district_id] ||= {
        district_id: district_id,
        name: district_name,
        counter_key.to_sym => 0,
        sites: [],
        total_sites: 0
      }

      district[counter_key.to_sym] += 1
      district[:sites] << site
    end

    [grouped, total_with_issue]
  end

  def self.enrich_regions_with_totals!(grouped, sites, counter_key)
    region_ids = sites.map { |s| s['region_id'] }.uniq

    region_ids.each do |region_id|
      region_name = sites.find { |s| s['region_id'] == region_id }['region_name']
      grouped[region_id] ||= {
        region_id: region_id,
        name: region_name,
        total_sites: 0,
        total_sites_with_issue: 0,
        districts: {}
      }
    end

    grouped.each do |_region_id, region|
      region[:total_sites] = 0
      region[:total_sites_with_issue] = 0

      region[:districts].each do |district_id, district|
        district[:total_sites] = sites.count { |s| s['district_id'] == district_id }
        region[:total_sites_with_issue] += district[counter_key.to_sym]
        region[:total_sites] += district[:total_sites]
      end

      if region[:districts].empty?
        region[:total_sites] = sites.count { |s| s['region_id'] == region[:region_id] }
      end

      region[:districts] = region[:districts].values.sort_by { |d| d[:name] }
    end
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
      .where('updated_at < ?', Time.now.beginning_of_day)
      .order(created_at: :desc).first
    yesterday_cache ? JSON.parse(yesterday_cache.value) : nil
  end

  def self.compare_stats(today_stats, yesterday_data)
    compare_district_counts(
      today_stats[:last_seen][:regions],
      yesterday_data[:last_seen] ? yesterday_data[:last_seen][:regions] : [],
      :sites_last_seen_greater_than_3_days_sites
    )

    compare_district_counts(
      today_stats[:last_activity][:regions],
      yesterday_data[:last_activity] ? yesterday_data[:last_activity][:regions] : [],
      :sites_last_activity_greater_than_3_days_sites
    )

    nil
  end

  def self.compare_district_counts(today_regions, yesterday_regions, key)
    all_regions = (today_regions + yesterday_regions).uniq { |r| r[:region_id] }

    all_regions.each do |region|
      region_id = region[:region_id]

      today_region = today_regions.find { |r| r[:region_id] == region_id } || { districts: [] }
      yest_region  = yesterday_regions.find { |r| r[:region_id] == region_id } || { districts: [] }

      all_district_ids = (today_region[:districts].map { |d| d[:district_id] } + yest_region[:districts].map { |d| d[:district_id] }).uniq

      all_district_ids.each do |district_id|
        today_d = today_region[:districts].find { |d| d[:district_id] == district_id }
        yest_d  = yest_region[:districts].find { |d| d[:district_id] == district_id }

        today_count = today_d ? today_d[key] : 0
        yest_count  = yest_d ? yest_d[key] : 0

        change = today_count - yest_count

        # === PRESSURE LOGIC (percent change calculation) ===
        change_percent =
          if yest_count == 0
            # No value yesterday: if there's a value today, it's a 100% increase
            # If today is also 0, then there's no change at all (0%)
            today_count == 0 ? 0 : 100
          elsif change == 0
            # No change in count => 0% difference
            0
          else
            # Standard percent change formula: ((new - old) / old) * 100
            # Rounded to 2 decimal places for presentation
            ((change.to_f / yest_count) * 100).round(2)
          end

        unless today_d
          today_d = {
            district_id: district_id,
            name: yest_d[:name],
            key => 0
          }
          today_region[:districts] << today_d
        end

        today_d[:yesterday]      = yest_count
        today_d[:change]         = change
        today_d[:change_percent] = change_percent
      end
    end
  end
end