
# frozen_string_literal: true

require 'rest-client'
require 'json'

# ==================================================
# CONFIGURATION
# ==================================================

VERIFY_ATTEMPTS = 5
VERIFY_INTERVAL = 1

# Adaptive pacing: delays follow how the master responds.
REQUEST_TIMEOUT = 120         # seconds to wait for an assign request
RESPONSE_DELAY_FACTOR = 2.0   # wait this many times the last response time
MIN_BATCH_DELAY = 1           # shortest wait between batches (seconds)
MIN_SITE_DELAY = 2            # shortest wait between sites (seconds)
MAX_DELAY = 120               # never wait longer than this (seconds)
MAX_RETRIES = 5               # consecutive failed requests before giving up on a site
RETRYABLE_STATUSES = [429, 500, 502, 503, 504].freeze

# Listed before ExceptionWithResponse is rescued, because
# RestClient's timeout classes are subclasses of it.
NETWORK_ERRORS = [
  RestClient::Exceptions::Timeout,
  RestClient::ServerBrokeConnection,
  Errno::ECONNREFUSED,
  Errno::ECONNRESET,
  Errno::EHOSTUNREACH,
  Errno::ETIMEDOUT
].freeze

def monotonic_now
  Process.clock_gettime(Process::CLOCK_MONOTONIC)
end

# Delay after a successful request: scales with how long the master
# took to respond, never below the operator's minimum.
def paced_delay(response_time, minimum)
  [[response_time * RESPONSE_DELAY_FACTOR, minimum].max, MAX_DELAY].min
end

# Delay after a failed request: the server's Retry-After header when it
# sends one, otherwise exponential backoff from the operator's minimum.
def backoff_delay(attempt, minimum, retry_after = nil)
  return [retry_after, MAX_DELAY].min if retry_after&.positive?

  base = [minimum, 1].max
  [base * (2**(attempt - 1)), MAX_DELAY].min
end

def retry_after_seconds(error)
  return nil unless error.respond_to?(:response) && error.response

  Float(error.response.headers[:retry_after], exception: false)
end

def unassigned_balance(location_id)
  LocationNpid.where(
    location_id: location_id,
    assigned: false
  ).count
end

def authenticate(url, username, password)
  response = RestClient.post(
    "#{url}/v1/login",
    {
      username: username,
      password: password
    }.to_json,
    {
      content_type: :json,
      accept: :json
    }
  )

  token = JSON.parse(response.body)['access_token']

  raise 'Access token was not returned by DDE master.' if token.to_s.empty?

  token
end

# Wait for the database balance to reflect an assignment.
# Returns the observed balance after verification.

def verify_assignment(location_id, previous_balance)
  VERIFY_ATTEMPTS.times do |attempt|
    sleep VERIFY_INTERVAL if attempt > 0

    current_balance = unassigned_balance(location_id)

    return current_balance if current_balance != previous_balance
  end

  unassigned_balance(location_id)
end

# ==================================================
# 1. CONNECTION DETAILS
# ==================================================

puts "\n=========================================="
puts " DDE MASTER - CONTROLLED NPID ASSIGNMENT"
puts "==========================================\n"

print 'Enter DDE IP or host: '
dde_ip = gets.chomp.strip

print 'Enter DDE port: '
dde_port = gets.chomp.strip

url = "http://#{dde_ip}:#{dde_port}"

print 'Enter username for DDE master: '
username = gets.chomp.strip

print 'Enter password for DDE master: '
password = gets.chomp

# ==================================================
# 2. SITE SELECTION
# ==================================================

puts "\nEnter location IDs separated by commas."
puts 'Example: 12,15,20'
puts 'Enter ALL to process all sites.'

print 'Location IDs (or ALL): '
site_selection = gets.chomp.strip

locations = Location.where.not(ip_address: nil)

unless site_selection.upcase == 'ALL'
  selected_ids = site_selection.split(',').map(&:strip).reject(&:empty?)

  if selected_ids.empty?
    puts 'No valid location IDs provided.'
    exit
  end

  locations = locations.where(location_id: selected_ids)
end

locations = locations.order(:location_id).to_a

if locations.empty?
  puts 'No matching sites found.'
  exit
end

# ==================================================
# 3. ASSIGNMENT PARAMETERS
# ==================================================

print "\nEnter target unassigned NPIDs per site: "
target_npids = gets.chomp.to_i

if target_npids <= 0
  puts 'Target must be greater than zero.'
  exit
end

print 'Enter NPIDs per batch (e.g. 50): '
batch_size = gets.chomp.to_i

if batch_size <= 0
  puts 'Batch size must be greater than zero.'
  exit
end

# ==================================================
# 4. EXECUTION PREVIEW
# ==================================================

puts "\n=========================================="
puts " EXECUTION PREVIEW"
puts "=========================================="

locations.each do |location|
  balance = unassigned_balance(location.location_id)
  required = [target_npids - balance, 0].max

  puts "\n#{location.name} (ID: #{location.location_id})"
  puts "Current unassigned: #{balance}"
  puts "Required: #{required}"
end

puts "\n=========================================="
puts "Target per site: #{target_npids}"
puts "Batch size: #{batch_size}"
puts "Delays: #{RESPONSE_DELAY_FACTOR}x the master's response time " \
     "(batches #{MIN_BATCH_DELAY}-#{MAX_DELAY}s, sites #{MIN_SITE_DELAY}-#{MAX_DELAY}s)"
puts "Retries per site: #{MAX_RETRIES} (on timeouts, 429 and 5xx)"
puts "=========================================="

print "\nProceed? Type YES to continue: "

unless gets.chomp.strip == 'YES'
  puts 'Operation cancelled.'
  exit
end

# ==================================================
# 5. AUTHENTICATION
# ==================================================

begin
  puts "\nAuthenticating with DDE master..."

  token = authenticate(url, username, password)

  puts 'Authentication successful.'

rescue StandardError => e
  puts "Authentication failed: #{e.message}"
  exit
end

# ==================================================
# 6. BATCH ASSIGNMENT
# ==================================================

assign_url = "#{url}/v1/assign_npids"

total_actually_assigned = 0
successful_sites = 0
failed_sites = 0
skipped_sites = 0
last_paced_delay = 0.0

locations.each_with_index do |location, index|

  location_id = location.location_id

  puts "\n=========================================="
  puts "SITE #{index + 1}/#{locations.count}"
  puts "#{location.name} (ID: #{location_id})"
  puts "=========================================="

  site_failed = false
  site_assigned = 0
  batch_number = 0

  begin

    # Always get the actual database balance.
    current_balance = unassigned_balance(location_id)

    remaining = [target_npids - current_balance, 0].max

    if remaining.zero?
      puts 'Target already achieved. Skipping site.'
      skipped_sites += 1
      next
    end

    puts "Initial unassigned balance: #{current_balance}"
    puts "NPIDs required: #{remaining}"

    consecutive_errors = 0

    while remaining > 0

      batch_number += 1

      # Capture balance before assignment and recalculate the requirement
      # in case another process has assigned NPIDs in the meantime.
      balance_before = unassigned_balance(location_id)
      remaining = [target_npids - balance_before, 0].max

      break if remaining.zero?

      requested_batch = [remaining, batch_size].min

      puts "\n------------------------------------------"
      puts "Batch: #{batch_number}"
      puts "Requesting: #{requested_batch} NPIDs"
      puts "------------------------------------------"

      # Submit assignment request, timing how long the master takes.
      request_error = nil
      started_at = monotonic_now

      begin
        response = RestClient::Request.execute(
          method: :post,
          url: assign_url,
          payload: {
            limit: requested_batch,
            location_id: location_id
          }.to_json,
          headers: {
            Authorization: token,
            content_type: :json,
            accept: :json
          },
          timeout: REQUEST_TIMEOUT
        )
      rescue *NETWORK_ERRORS => e
        request_error = e
      rescue RestClient::ExceptionWithResponse => e
        # Client errors such as 401 or 422 will not fix themselves:
        # let them fail the site.
        raise unless RETRYABLE_STATUSES.include?(e.http_code)

        request_error = e
      end

      response_time = monotonic_now - started_at
      puts "Response time: #{response_time.round(2)}s"

      if request_error
        puts "Request failed: #{request_error.class}: #{request_error.message}"
      else
        puts "HTTP Status: #{response.code}"

        begin
          puts "API Response: #{JSON.parse(response.body).inspect}"
        rescue JSON::ParserError
          puts "API Response: #{response.body}"
        end
      end

      # Verify actual assignment through database balance. This also runs
      # after a failed request, because the master may have assigned the
      # NPIDs before the error reached us.
      puts 'Verifying actual assignment...'

      balance_after = verify_assignment(
        location_id,
        balance_before
      )

      # Assigning NPIDs adds new unassigned rows for the site,
      # so a successful batch increases the unassigned balance.
      actually_assigned = balance_after - balance_before

      if actually_assigned <= 0

        if request_error
          consecutive_errors += 1

          if consecutive_errors > MAX_RETRIES
            puts "\nGiving up on this site after #{MAX_RETRIES} retries."
            site_failed = true
            break
          end

          retry_delay = backoff_delay(
            consecutive_errors,
            MIN_BATCH_DELAY,
            retry_after_seconds(request_error)
          )

          puts "Nothing was assigned. Retry #{consecutive_errors}/#{MAX_RETRIES} " \
               "in #{retry_delay.round(2)} seconds..."
          sleep retry_delay
          next
        end

        puts "\nWARNING: Unassigned NPID balance did not increase."
        puts "Balance before: #{balance_before}"
        puts "Balance after: #{balance_after}"
        puts 'Stopping this site to prevent repeated assignments.'

        site_failed = true
        break
      end

      consecutive_errors = 0

      # Update counters using actual database changes.
      site_assigned += actually_assigned
      total_actually_assigned += actually_assigned

      remaining = [target_npids - balance_after, 0].max

      puts "\nBATCH RESULT"
      puts "Requested: #{requested_batch}"
      puts "Actually assigned (observed): #{actually_assigned}"
      puts "Unassigned balance: #{balance_after}"
      puts "Remaining to target: #{remaining}"

      # Slow responses mean a busy master: wait longer before the next batch.
      last_paced_delay = paced_delay(response_time, MIN_BATCH_DELAY)

      # If the API assigned fewer than requested,
      # continue based on the actual remaining balance.
      if remaining > 0 && last_paced_delay > 0
        puts "Waiting #{last_paced_delay.round(2)} seconds before next batch " \
             "(response took #{response_time.round(2)}s)..."
        sleep last_paced_delay
      end

    end

    if site_failed
      failed_sites += 1
    else
      successful_sites += 1
      puts "\nSite processing completed."
    end

  rescue RestClient::ExceptionWithResponse => e

    puts "\nHTTP ERROR: #{e.message}"
    puts "Response: #{e.response&.body}"

    failed_sites += 1

  rescue StandardError => e

    puts "\nERROR: #{e.message}"
    puts e.backtrace.first(5)

    failed_sites += 1

  ensure

    puts "\nSITE SUMMARY"
    puts "Site: #{location.name}"
    puts "Observed NPID assignments: #{site_assigned}"
    puts "Current unassigned balance: #{unassigned_balance(location_id)}"

    # Use the longer of the site minimum and the pacing
    # from the master's most recent response.
    site_wait = [MIN_SITE_DELAY, last_paced_delay].max

    if index < locations.length - 1 && site_wait > 0
      puts "\nWaiting #{site_wait.round(2)} seconds before next site..."
      sleep site_wait
    end

  end

end

# ==================================================
# 7. FINAL SUMMARY
# ==================================================

puts "\n"
puts "=========================================="
puts " FINAL NPID ASSIGNMENT REPORT"
puts "=========================================="

puts "Sites selected: #{locations.count}"
puts "Successfully processed: #{successful_sites}"
puts "Skipped (target achieved): #{skipped_sites}"
puts "Failed/stopped: #{failed_sites}"

puts "Total NPIDs actually assigned (observed): #{total_actually_assigned}"

puts "=========================================="
puts "Operation completed."
puts "=========================================="
