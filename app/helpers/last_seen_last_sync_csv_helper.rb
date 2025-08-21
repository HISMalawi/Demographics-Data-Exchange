
module LastSeenLastSyncCsvHelper
  require 'csv'

  # Generate CSV for hierarchical site data (regions -> districts -> sites)
  def generate_sites_csv(data, options = {})
    # Default options
    default_options = {
      days_field: 'days_since_last_activity',
      headers: ['region', 'district', 'site_name', 'ip_address', 'days_since_last_activity'],
      data_key: :regions
    }
    
    options = default_options.merge(options)
    
    CSV.generate(headers: true) do |csv|
      # Add headers
      csv << options[:headers]
      
      # Extract sites from the nested structure
      if data.is_a?(Hash) && data[options[:data_key]]
        data[options[:data_key]].each do |region|
          region_name = region[:name]
          
          (region[:districts] || []).each do |district|
            district_name = district[:name]
            
            (district[:sites] || []).each do |site|
              csv << [
                region_name,
                district_name,
                site['site_name'],
                site['ip_address'],
                site[options[:days_field]]
              ]
            end
          end
        end
      end
    end
  end
end