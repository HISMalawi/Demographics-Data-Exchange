class ApplicationJob < ActiveJob::Base
  unique :until_executed, lock_ttl: 1.hour, on_conflict: :log
  sidekiq_options retry: false
end
