class User < ApplicationRecord
   default_scope { where(voided: false) }
   
   validates_presence_of :username, :password_digest
   validates :username, uniqueness: true
   mattr_accessor :current
   #encrypt password
   has_secure_password

end
