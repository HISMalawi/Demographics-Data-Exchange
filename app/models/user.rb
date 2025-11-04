class User < ApplicationRecord
   default_scope { where(voided: false) }
   
   validates_presence_of :username, :password_digest
   validates :username, uniqueness: true
   mattr_accessor :current
   #encrypt password
   has_secure_password

   validate :validate_location_consistency, unless: -> { ENV['MASTER'] == 'true' }

   def self.non_default_location!
      user = where(default_user: false)

      users = where(default_user: false)
      location_ids = users.pluck(:location_id).compact.uniq

      if location_ids.empty?
         nil
      elsif location_ids.size > 1
         raise StandardError, "<strong>Unresolved Conflict:</strong> Found multiple locations (#{location_ids.join(', ')})."
      else 
         Location.find_by(location_id: location_ids.first)
      end 
   end

   private 
  
   def validate_location_consistency
      return if default_user?
      
      if location_id.nil?
         errors.add(:location_id, "cannot be nil for non-default users")
         return
      end

      other_users = User.unscoped
                        .where(voided: false, default_user: false)
                        .where.not(user_id: user_id)
      
      return unless other_users.exists?
      
      existing_locations = other_users.pluck(:location_id).compact.uniq
      
      return if existing_locations.empty?
      
      if existing_locations.length > 1
         errors.add(:base, "Data integrity issue: multiple locations found for non-default users on proxy")
         return
      end
      
      unless existing_locations.include?(location_id)
         errors.add(:location_id, "must match the location of existing non-default users (expected: #{existing_locations.first}) on proxy")
      end
   end

end
