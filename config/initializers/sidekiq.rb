# config/initializers/sidekiq.rb

Sidekiq.configure_server do |config|
    config.on(:startup) do
      Sidekiq::Scheduler.reload_schedule!
    end
end
  
Rails.application.configure do
    config.active_job.queue_adapter = :sidekiq
end
  