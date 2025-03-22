class ApplicationJob < ActiveJob::Base
  unique :until_executed, on_conflict: :log
  sidekiq_options retry: false
end
