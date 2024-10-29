require 'sidekiq'
require 'sidekiq-cron'
require 'redis'
require 'yaml'

# Load sidekiq.yml config
def load_sidekiq_config
  YAML.load_file(Rails.root.join('config', 'sidekiq.yml'))
end

# Save the Redis DB choice to sidekiq.yml
def store_db_choice(db)
  config = load_sidekiq_config
  config[:redis][:url] = "redis://localhost:6379/#{db}"
  
  File.open(Rails.root.join('config', 'sidekiq.yml'), 'w') do |f|
    f.write(config.to_yaml)
  end
end

# Read Redis DB choice from sidekiq.yml
def read_db_choice
  config = load_sidekiq_config
  config[:redis][:url].match(/redis:\/\/localhost:6379\/(\d+)/)[1].to_i
rescue
  nil
end

# Find the first available Redis DB
def find_free_redis_db(redis_client, max_db = 15)
  (0..max_db).each do |db|
    redis_client.select(db)
    size = redis_client.dbsize
    return db if size == 0
  end
  raise "No free Redis databases available."
end

def store_master_schedule_config
  schedule_file = Rails.root.join('config', 'schedule.yml')

    if File.exist?(schedule_file)
      config = YAML.load_file(schedule_file)

      unless config.key?('dashboard_socket')
        config['dashboard_socket'] = {
            'cron' => '0 0 * * *',
            'class' => 'DashboardSocketDataJob',
            'queue' => 'default',
            'description' => 'Refreshes dashboard details'
          }

           
        File.open(Rails.root.join('config', 'schedule.yml'), 'w') do |f|
          f.write(config.to_yaml)
        end
      end
    else
      Rails.logger.warn "Schedule file not found at #{schedule_file}"
      {}
    end
end

redis = Redis.new(url: 'redis://localhost:6379/0')
free_db = read_db_choice || find_free_redis_db(redis)

# Store the selected DB back in the sidekiq.yml file
store_db_choice(free_db)

if ActiveRecord::Base.connection.data_source_exists?('npids')
  store_master_schedule_config
end

Sidekiq.configure_server do |config|
  config.redis = { url: "redis://localhost:6379/#{free_db}" }
end

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://localhost:6379/#{free_db}" }
end

Rails.application.configure do
  config.active_job.queue_adapter = :sidekiq
end

schedule_file = "config/schedule.yml"

if File.exist?(schedule_file) && Sidekiq.server?
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
end
