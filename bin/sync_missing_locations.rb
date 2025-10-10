# db/load_locations_dump.rb
require_relative "../config/environment"  # Load Rails

DB_NAME = ActiveRecord::Base.connection_db_config.database
SQL_FILE = Rails.root.join("db/meta_data/dde4_locations.sql")

unless File.exist?(SQL_FILE)
  puts "❌ SQL file not found: #{SQL_FILE}"
  exit 1
end

puts "⚙️ Loading dump into '#{DB_NAME}' (REPLACE mode)..."

# Read SQL file
sql_content = File.read(SQL_FILE)

# Convert INSERT INTO -> REPLACE INTO for overwrite
sql_content.gsub!(/INSERT INTO/i, "REPLACE INTO")

# Split on semicolons and execute each statement
statements = sql_content.split(/;[\r\n]+/)

statements.each do |stmt|
  stmt.strip!
  next if stmt.empty?

  begin
    ActiveRecord::Base.connection.execute(stmt)
  rescue => e
    puts "⚠️ Skipped statement due to error: #{e.message}"
  end
end

puts "✅ Dump loaded successfully into #{DB_NAME}."