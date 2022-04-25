# Puma can serve each request in a thread from an internal thread pool.
# The threads method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads_count = ENV.fetch('RAILS_MAX_THREADS') { 10 }
threads 5, threads_count

# Specifies the port that Puma will listen on to receive requests; default is 3000.
#
port        ENV.fetch('PORT') { 5000 }

# Specifies the environment that Puma will run in.
#
environment ENV.fetch('RAILS_ENV') { 'production' }

# Specifies the number of workers to boot in clustered mode.
workers ENV.fetch('WEB_CONCURRENCY') { 12 }

# Use the preload_app! method when specifying a workers number.

preload_app!

# Allow puma to be restarted by rails restart command.
plugin :tmp_restart

rackup '/var/www/dde4/config.ru'
