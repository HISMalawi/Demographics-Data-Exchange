module SyncingService
  class SyncErrorProcessor
    def self.process(sync_errors)
      districts = {}

      sites_with_errors = Hash.new { |h, k| h[k] = Set.new }

      sync_errors.each do |error|
        district_id = error.try(:district_id)
        district_name = error.try(:district_name)
        site_id = error.try(:site_id)

        next unless district_id && district_name && site_id

        districts[district_id] ||= { name: district_name, sync_errors: [] }
        districts[district_id][:sync_errors] << error
        sites_with_errors[district_id] << site_id
      end

      total_sites_per_district = Location.where(activated: true).group(:district_id).count

      districts.each do |district_id, info|
        info[:sites_with_errors] = sites_with_errors[district_id].size
        info[:total_sites] = total_sites_per_district[district_id] || 0
      end

      {
        sync_errors: sync_errors.to_a,
        sync_error_districts: { districts: districts }
      }
    end

    def self.build_sync_summary_data(districts)
      {
        total_sites: districts.values.sum { |d| d[:total_sites] || 0 },
        total_sites_with_issue: districts.values.sum { |d| d[:sites_with_errors] || 0 },
        districts: districts.values
      }
    end
  end
end