module FootPrintService
  
  def self.create(person)
    footprint = CouchdbFootPrint.create(
       person_id: person.couchdb_person_id,
       user_id: User.current.couchdb_user_id)
       
    return footprint
  end

  def self.client_movements
    categories = ActiveRecord::Base.connection.select_all <<EOF
    SELECT * FROM tmp_foot_print_category_stats;
EOF
   
    data = []
    (categories || []).each do |c|
      data << {
        category: c["category"],
        number_of_clients: c["number_of_clients"]
      }
    end

    return data
  end

  def self.by_category(category)
    data = ActiveRecord::Base.connection.select_all <<EOF
    SELECT t.couchdb_person_id, t2.couchdb_location_id, l.name,
    p.npid, p.given_name, p.family_name, p.birthdate, p.gender
    FROM tmp_foot_print_categories t 
    INNER JOIN tmp_foot_print_visited_location t2 
    ON t2.foot_print_category_id = t.foot_print_category_id
    INNER JOIN locations l ON l.couchdb_location_id = t2.couchdb_location_id
    INNER JOIN people p ON p.couchdb_person_id = t.couchdb_person_id
    WHERE t.category = #{category};
EOF

    people = {} 
    (data || []).each do |footprint|
      couchdb_person_id = footprint["couchdb_person_id"]

      if people[couchdb_person_id].blank?
        people[couchdb_person_id] = {
         demographics: {
           given_name:  footprint["given_name"],
           family_name: footprint["family_name"],
           gender: 	footprint["gender"],
           birthdate: 	footprint["birthdate"],
           npid: 	footprint["npid"]
         },
         footprint_info: []
        }
      end
        
      people[couchdb_person_id][:footprint_info] << {
        site_name: footprint["name"]
      }
      
    end

    return people
  end
  
end
