# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

#Update to DDE 4
Config.create!(config: 'push_seq_update',
               config_value: 0,
               description: 'push vector clock updates',
               uuid: 'ba45bb9c-9dca-11eb-a899-dc41a91e235e') unless Config.find_by_config('push_seq_update')

Config.create!(config: 'push_seq_new',
               config_value: 0,
               description: 'push vector clock new records',
               uuid: '6dcfeb1f-d980-11eb-9643-00ffc8ad464b') unless Config.find_by_config('push_seq_new')

Config.create!(config: 'pull_seq_update',
               config_value: 0,
               description: 'pull vector clock updates',
               uuid: 'c22d75c6-9dca-11eb-a899-dc41a91e235e') unless Config.find_by_config('pull_seq_update')

Config.create!(config: 'pull_seq_new',
               config_value: 0,
               description: 'pull vector clock new',
               uuid: '5ba698fe-d980-11eb-9643-00ffc8ad464b') unless Config.find_by_config('pull_seq_new')

Config.create!(config: 'npid_seq',
               config_value: 0,
               description: 'NPID pull vector clock',
               uuid: 'ebc28cab-b7d8-11eb-8cf6-dc41a91e235e') unless Config.find_by_config('npid_seq')

DashboardStat.find_or_create_by(name: 'npid_balance',
                                value: {})

DashboardStat.find_or_create_by(name: 'location_npid_balance',
                                value: {})

DashboardStat.find_or_create_by(name: 'dashboard_stats',
                                value: {})

unless User.exists?
#Load proxy Meta data
metadata_sql_files = %w[dde4_metadata dde4_locations]
connection = ActiveRecord::Base.connection
(metadata_sql_files || []).each do |metadata_sql_file|
  puts "Loading #{metadata_sql_file} metadata sql file"
  sql = File.read("db/meta_data/#{metadata_sql_file}.sql")
    statements = sql.split(/;$/)
    statements.pop

    ActiveRecord::Base.transaction do
      statements.each do |statement|
        connection.execute(statement)
      end
    end
    puts "Loaded #{metadata_sql_file} metadata sql file successfully"
    puts ''
  end
end

# === Add foreign key constraints ===
connection = ActiveRecord::Base.connection

begin
  connection.execute <<-SQL
    ALTER TABLE mailer_districts
    ADD CONSTRAINT fk_mailer_districts_district
    FOREIGN KEY (district_id)
    REFERENCES districts(district_id);
  SQL

  puts "Added foreign key to mailer_districts → districts"
rescue => e
  puts "Could not add foreign key to mailer_districts: #{e.message}"
end

begin
  connection.execute <<-SQL
    ALTER TABLE mailing_logs
    ADD CONSTRAINT fk_mailing_logs_district
    FOREIGN KEY (district_id)
    REFERENCES districts(district_id);
  SQL

  puts "Added foreign key to mailing_logs → districts"
rescue => e
  puts "Could not add foreign key to mailing_logs: #{e.message}"
end
