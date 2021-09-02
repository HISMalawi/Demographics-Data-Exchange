module FootPrintService

  def self.create(person)
   footprint = FootPrint.where('person_uuid = ? AND
                                program_id = ? AND
                                date(created_at) = ?',
                                person[:person_uuid],
                                person[:program_id],
                                Time.now.strftime('%Y-%m-%d'))
   if footprint.blank?
       footprint = FootPrint.create(
          person_uuid: person[:person_uuid],
          user_id: person[:user_id],
          program_id: person[:program_id],
          location_id: person[:location_id]
       )
   end
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
    p.npid, p.given_name, p.family_name, p.birthdate, p.gender,
    f.created_at , f.updated_at, u.username
    FROM tmp_foot_print_categories t
    INNER JOIN tmp_foot_print_visited_location t2
    ON t2.foot_print_category_id = t.foot_print_category_id
    INNER JOIN people p ON p.couchdb_person_id = t.couchdb_person_id
    INNER JOIN foot_prints f ON f.foot_print_id = t2.foot_print_id
    INNER JOIN users u ON f.user_id = u.user_id
    INNER JOIN locations l ON l.location_id = u.location_id
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
        site_name: footprint["name"],
        created_at: footprint["created_at"],
        updated_at: footprint["updated_at"],
        username: footprint["username"]
      }

    end

    return people
  end

end
