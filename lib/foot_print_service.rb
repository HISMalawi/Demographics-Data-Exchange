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
  
end
