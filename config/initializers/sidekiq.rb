require 'sidekiq'
require 'sidekiq/cron'
require 'yaml'

sidekiq_config = YAML.load_file(Rails.root.join('config', 'sidekiq.yml'))
redis_url = sidekiq_config.fetch(:redis).fetch(:url)

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  # Load cron jobs from schedule.yml
  schedule_file = 'config/schedule.yml'

  if File.exist?(schedule_file)
    schedule = YAML.load_file(schedule_file)
    Sidekiq::Cron::Job.load_from_hash(schedule)
    Rails.logger.info "Loaded #{schedule.keys.count} cron job(s) from #{schedule_file}"
  else
    Rails.logger.warn "Schedule file not found: #{schedule_file}"
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end