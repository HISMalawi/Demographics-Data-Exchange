require 'csv'

user = User.where(username: 'admin').first
[['South','Southern Region'],['Centre','Central Region'],['North','Northern Region']].each do |name, desc|
  r = Region.create(name: name, description: desc, creator: user.id)
  puts "Created region: #{r.name} ...."

end

CSV.foreach("#{Rails.root}/app/assets/data/health_facilities.csv", headers: true, encoding: 'ISO-8859-1') do |row|
  next if row[0].blank? || row[3].blank? || row[4].blank?

  district_name = row[0]
  region_name   = row[4]
  site_name     = row[3]

  district      = Location.where(name: district_name.to_s).first
  site          = Location.where(name: site_name.to_s).first

  case region_name.to_s.squish
    when "Northern"
      region = Region.where(name: "North").first
    when "Central East"
      region = Region.where(name: "Centre").first
    when "Central West"
      region = Region.where(name: "Centre").first
    when "South East"
      region = Region.where(name: "South").first
    when "South West"
      region = Region.where(name: "South").first
    when "South East"
      region = Region.where(name: "South").first
  end
  
  begin
    puts "District: #{district_name}(#{district.location_id}),
      Region: #{region_name}(#{region.id}), Site: #{site_name}(#{site.location_id})"
    rd = RegionDistrict.where(district_id: district.location_id)
    if rd.blank?
      puts "Creating link between #{region_name} and #{district_name}"
      RegionDistrict.create(region_id: region.id, district_id: district.location_id)
    end

      puts "Creating link between #{district_name} and #{site_name}"
      DistrictSite.create(district_id: district.location_id, site_id: site.location_id)
  rescue
    puts "District: #{district_name}(#{district.location_id}),Region: #{region_name}, Site: #{site_name}"
  end
end