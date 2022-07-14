class ApplicationJob < ActiveJob::Base
    sidekiq_options retry: false
end
