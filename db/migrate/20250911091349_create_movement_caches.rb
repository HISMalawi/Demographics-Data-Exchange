class CreateMovementCaches < ActiveRecord::Migration[7.0]
  def change
    return unless ENV['MASTER'] == 'true'

    create_table :movement_caches, id: false, primary_key: :person_uuid do |t|
      t.string :person_uuid, limit: 36, null: false, primary_key: true
      t.integer :sites_visited, null: false

      t.timestamps
    end
    add_index :movement_caches, :sites_visited
    puts 'Populating initial cache data ....'
    sql = <<-SQL
        INSERT INTO movement_caches (person_uuid, sites_visited, created_at, updated_at)
        SELECT#{' '}
            person_uuid,
            COUNT(DISTINCT location_id) AS sites_visited,
            NOW() AS created_at,
            NOW() AS updated_at
        FROM foot_prints
        GROUP BY person_uuid
        ON DUPLICATE KEY UPDATE
            sites_visited = VALUES(sites_visited),
            updated_at = VALUES(updated_at);
    SQL
    ActiveRecord::Base.connection.execute(sql)
  end
end
