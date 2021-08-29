# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end

puts @environment
case @environment
when 'production'
  every 5.minutes do
    runner 'bin/sync.rb'
  end
when 'development'
  every 1.minute do
    runner 'bin/sync.rb'
  end
end



# Learn more: http://github.com/javan/whenever
