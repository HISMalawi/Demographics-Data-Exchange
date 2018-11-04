
def buildTables
  ActiveRecord::Base.connection.execute <<EOF
  CREATE TABLE IF NOT EXISTS tmp_foot_print_categories (
      foot_print_category_id INT AUTO_INCREMENT,
      couchdb_person_id VARCHAR(255) NOT NULL,
      category INT(11) NOT NULL,
      PRIMARY KEY (foot_print_category_id)
  )  ENGINE=INNODB;
EOF

  ActiveRecord::Base.connection.execute <<EOF
  CREATE TABLE IF NOT EXISTS tmp_foot_print_visited_location (
      foot_print_visited_location_id INT AUTO_INCREMENT,
      foot_print_category_id INT(11) NOT NULL,
      couchdb_location_id VARCHAR(255) NOT NULL,
      PRIMARY KEY (foot_print_visited_location_id)
  )  ENGINE=INNODB;
EOF

  ActiveRecord::Base.connection.execute <<EOF
  CREATE TABLE IF NOT EXISTS tmp_foot_print_category_stats (
      foot_print_category_stat_id INT AUTO_INCREMENT,
      category INT(11) NOT NULL,
      number_of_clients INT(11) NOT NULL,
      PRIMARY KEY (foot_print_category_stat_id)
  )  ENGINE=INNODB;
EOF


end

def check_if_script_already_running
  file_exist = File.file?("#{Rails.root}/tmp/client-tracker.pid")
  return (file_exist == true ? true : false)
end

def start
  buildTables

  script_already_running = check_if_script_already_running	

  if script_already_running	
    puts "Script is already running, wait until it is done ...."
    return
  else
    File.open("#{Rails.root}/tmp/client-tracker.pid")
  end

  file_exist = File.file?("#{Rails.root}/log/client-tracker.log")
  foot_print_id = 0

  if file_exist 
    file = File.read("#{Rails.root}/log/client-tracker.log") 
    foot_print_id = file.split(":")[1].to_i
  else
    file = File.open("#{Rails.root}/log/client-tracker.log", "w")
    file.syswrite("foot_print_id: 0")
  end

  categories = {}
  foot_print_data = FootPrint.where("foot_print_id >= ? AND u.location_id <> 1077", 
    foot_print_id).joins("INNER JOIN users u 
    ON u.couchdb_user_id = foot_prints.couchdb_user_id").group("foot_prints.couchdb_person_id")

  (foot_print_data || []).each_with_index do |f, i|


    couchdb_user_id = f.couchdb_user_id
    couchdb_person_id = f.couchdb_person_id
    couchdb_location_id = 0
    
    next if couchdb_person_id.blank?

    begin
      user_couchdb_location_id = User.where(couchdb_user_id: couchdb_user_id).first.couchdb_location_id
    rescue
      puts "Crashed >>>>>>>>>>> #{i}"
      next
    end
     
    data = FootPrint.joins("INNER JOIN users u 
      ON u.couchdb_user_id = foot_prints.couchdb_user_id").where("couchdb_person_id = ?", 
      couchdb_person_id).group("u.location_id").select("u.username, u.couchdb_location_id")

    if data.length > 1
      puts "############ #{couchdb_person_id}"
      insertCategory(couchdb_person_id, data)
    end

    if i == 1000
      #break
    end

  end

  buildStatTable
  system "rm #{Rails.root}/tmp/client-tracker.pid"
  file.syswrite("foot_print_id: #{foot_print_id}")
end

def buildStatTable
  ActiveRecord::Base.connection.execute <<EOF
  INSERT INTO tmp_foot_print_category_stats 
  SELECT NULL, category, count(category) FROM people p
  INNER JOIN tmp_foot_print_categories c ON c.couchdb_person_id = p.couchdb_person_id
  WHERE given_name NOT LIKE '%test%' AND family_name NOT LIKE '%test%'
  GROUP BY category;
EOF

end

def insertCategory(couchdb_person_id, data)
  
  tmp_foot_print_categories = ActiveRecord::Base.connection.select_one <<EOF
  SELECT * from tmp_foot_print_categories 
  WHERE couchdb_person_id = "#{couchdb_person_id}";
EOF
  
  if tmp_foot_print_categories.blank?
    ActiveRecord::Base.connection.execute <<EOF
    INSERT INTO tmp_foot_print_categories VALUES(NULL, "#{couchdb_person_id}", #{data.length});
EOF

    table1 = ActiveRecord::Base.connection.select_one <<EOF
    SELECT foot_print_category_id FROM tmp_foot_print_categories
    WHERE couchdb_person_id = "#{couchdb_person_id}";
EOF

    (data || []).each do |d|
      foreign_id = table1["foot_print_category_id"]
      couchdb_location_id = d["couchdb_location_id"]
      
      tmp_foot_print_categories = ActiveRecord::Base.connection.execute <<EOF
      INSERT INTO tmp_foot_print_visited_location VALUES(NULL, #{foreign_id}, "#{couchdb_location_id}");
EOF

    end

  else
    ActiveRecord::Base.connection.execute <<EOF
    UPDATE tmp_foot_print_categories SET category = #{data.length} WHERE couchdb_person_id = "#{couchdb_person_id}";
EOF

    table1 = ActiveRecord::Base.connection.select_one <<EOF
    SELECT foot_print_category_id FROM tmp_foot_print_categories
    WHERE couchdb_person_id = "#{couchdb_person_id}";
EOF

    foot_print_category_id = table1["foot_print_category_id"]
    ActiveRecord::Base.connection.execute <<EOF
    DELETE FROM tmp_foot_print_visited_location WHERE foot_print_category_id = #{foot_print_category_id};
EOF

    (data || []).each do |d|
      foreign_id = foot_print_category_id
      couchdb_location_id = d["couchdb_location_id"]
      
      tmp_foot_print_categories = ActiveRecord::Base.connection.execute <<EOF
      INSERT INTO tmp_foot_print_visited_location VALUES(NULL, #{foreign_id}, "#{couchdb_location_id}");
EOF

    end
    
  end

end



start
