# config/initializers/sidekiq.rb
require 'redis'

redis = Redis.new(url: 'redis://localhost:6379/0') # Start with db 0

def find_free_redis_db(redis_client, max_db = 15)
  (0..max_db).each do |db|
    redis_client.select(db)
    size = redis_client.dbsize
    return db if size == 0
  end
  raise "No free Redis databases available."
end

free_db = find_free_redis_db(redis)

Sidekiq.configure_server do |config|
    config.on(:startup) do
      Sidekiq::Scheduler.reload_schedule!
    end

    config.redis = { db: free_db, url: "redis://localhost:6379/#{free_db}" }
end

Sidekiq.configure_client do |config|
    config.redis = { db: free_db, url: "redis://localhost:6379/#{free_db}" }
end
  
Rails.application.configure do
    config.active_job.queue_adapter = :sidekiq
end
  