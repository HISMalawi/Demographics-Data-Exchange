require 'sidekiq'
require 'sidekiq-cron'
require 'redis'
require 'yaml'

SIDEKIQ_YML_PATH = Rails.root.join('config', 'sidekiq.yml')
SCHEDULE_YML_PATH = Rails.root.join('config', 'schedule.yml')

# ---------------------------
# Cron configs
# ---------------------------
def cron_config(cron_time, job_class_name, queue_name, description)
  {
    'cron' => cron_time,
    'class' => job_class_name,
    'queue' => queue_name,
    'description' => description
  }
end

DDE4_SYNC_CONFIGS = cron_config('*/5 * * * *', 'SyncJob', 'sync', 'Syncs data demographics and NPIDs with master')
DASHBOARD_SOCKET_CONFIGS = cron_config('0 0 * * *', 'DashboardSocketDataJob', 'default', 'Refreshes dashboard details')
LOW_NPID_NOTIFICATION_CONFIGS = cron_config('30 7 * * *', 'LowNpidNotificationJob', 'low_npid_notification', 'Sends low NPIDs email notifications')
LAST_SEEN_LAST_SYNCED_CONFIGS = cron_config('30 7 * * *', 'LastSeenLastSyncedJob', 'last_seen_last_synced', 'Sends last seen and last sync email notifications')
ARCHIVE_SYNC_ERRORS_CONFIG = cron_config('30 7 * * *', 'ArchiveSyncErrorsJob', 'archive_sync_errors', 'Archives sync errors')

# ---------------------------
# Helpers
# ---------------------------
def load_yaml(path)
  File.exist?(path) ? YAML.load_file(path) || {} : {}
end

def save_yaml(path, hash)
  File.write(path, hash.to_yaml)
end

# ---------------------------
# Redis DB helpers
# ---------------------------
def read_db_choice
  config = load_yaml(SIDEKIQ_YML_PATH).transform_keys(&:to_sym)
  url = config.dig(:redis, :url)
  url.match(/redis:\/\/localhost:6379\/(\d+)/)[1].to_i if url
rescue
  nil
end

def find_free_redis_db(max_db = 15)
  redis = Redis.new(url: 'redis://localhost:6379/0')
  (0..max_db).each do |db|
    redis.select(db)
    return db if redis.dbsize == 0
  end
  raise "No free Redis DB available!"
end

# ---------------------------
# Determine queues and cron schedule
# ---------------------------
def determine_queues_and_schedule
  default_queues = ['default', 'sync']
  schedule = {}

  begin
    if ActiveRecord::Base.connection.data_source_exists?('npids')
      queues = ['default', 'location_npid', 'npid_pool', 'email_notifications', 'archive_sync_errors']
      schedule = {
        'dashboard_socket' => DASHBOARD_SOCKET_CONFIGS,
        'low_npid_notification' => LOW_NPID_NOTIFICATION_CONFIGS,
        'last_seen_last_synced' => LAST_SEEN_LAST_SYNCED_CONFIGS,
        'archive_sync_errors' => ARCHIVE_SYNC_ERRORS_CONFIG
      }
    else
      queues = default_queues
      schedule = { 'dde4_sync' => DDE4_SYNC_CONFIGS }
    end
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
    queues = default_queues
    schedule = { 'dde4_sync' => DDE4_SYNC_CONFIGS }
  end

  [queues, schedule]
end

# ---------------------------
# Update sidekiq.yml safely
# ---------------------------
def update_sidekiq_config(free_db, queues)
  config = load_yaml(SIDEKIQ_YML_PATH).transform_keys(&:to_sym)
  config[:redis] ||= {}
  config[:redis][:url] = "redis://localhost:6379/#{free_db}"
  config[:queues] = queues
  save_yaml(SIDEKIQ_YML_PATH, config)
end

# ---------------------------
# Rewrite schedule.yml file
# ---------------------------
def rewrite_schedule_file(schedule_hash)
  save_yaml(SCHEDULE_YML_PATH, schedule_hash)
end

# ---------------------------
# Redis DB & queues
# ---------------------------
free_db = read_db_choice || find_free_redis_db
queues, schedule_hash = determine_queues_and_schedule

# Update sidekiq.yml
update_sidekiq_config(free_db, queues)

# Rewrite schedule.yml based on current db state
rewrite_schedule_file(schedule_hash)

# ---------------------------
# Sidekiq server/client config
# ---------------------------
Sidekiq.configure_server do |config|
  config.redis = { url: "redis://localhost:6379/#{free_db}" }

  # Load cron schedule from file
  if File.exist?(SCHEDULE_YML_PATH)
    Sidekiq::Cron::Job.load_from_hash(load_yaml(SCHEDULE_YML_PATH))
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://localhost:6379/#{free_db}" }
end

Rails.application.configure do
  config.active_job.queue_adapter = :sidekiq
end