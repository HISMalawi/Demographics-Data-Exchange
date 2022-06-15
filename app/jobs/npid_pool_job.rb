class NpidPoolJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
    npid_balance = Npid.all.group(:assigned).count
    File.write("#{Rails.root}/log/npid_balance.json", npid_balance.to_json)
  end
end
