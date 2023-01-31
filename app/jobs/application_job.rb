class ApplicationJob < ActiveJob::Base
    unique :until_executing, :on_conflict => :log
    sidekiq_options retry: false
end
