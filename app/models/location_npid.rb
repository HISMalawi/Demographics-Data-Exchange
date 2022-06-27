class LocationNpid < ApplicationRecord
    after_commit :allocated_npid_balance

    def allocated_npid_balance
        location_npid_balance = LocationNpid.all.group(:assigned).count
        File.write("#{Rails.root}/log/location_npid_balance.json", location_npid_balance.to_json)
    end
end
