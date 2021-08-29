# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

#Update to DDE 4
Config.create!(config: 'host',
               config_value: '10.44.0.48',
               description: 'DDE Master IP/Path',
               uuid: '94f07d78-9dca-11eb-a899-dc41a91e235e') unless Config.find_by_config('host')

Config.create!(config: 'peer_port',
               config_value: '8000',
               description: 'DDE Master Port',
               uuid: 'a0f576e9-9dca-11eb-a899-dc41a91e235e') unless Config.find_by_config('peer_port')


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

Config.create!(config: 'sync_pwd',
               config_value: 'dde_sync_password',
               description: 'Password for syncing user',
               uuid: 'b32599a5-a072-11eb-a899-dc41a91e235e') unless Config.find_by_config('sync_pwd')


Config.create!(config: 'sync_user',
               config_value: 'dde_sync_user',
               description: 'User for syncing',
               uuid: 'b5c0ecd1-a072-11eb-a899-dc41a91e235e') unless Config.find_by_config('sync_user')

Config.create!(config: 'npid_seq',
               config_value: 0,
               description: 'NPID pull vector clock',
               uuid: 'ebc28cab-b7d8-11eb-8cf6-dc41a91e235e') unless Config.find_by_config('npid_seq')

unless User.exists?
#Load proxy Meta data
connection = ActiveRecord::Base.connection
sql = File.read('db/meta_data/dde4_metadata.sql')
  statements = sql.split(/;$/)
  statements.pop

  ActiveRecord::Base.transaction do
    statements.each do |statement|
      connection.execute(statement)
    end
  end
end
