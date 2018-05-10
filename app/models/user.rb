class User < ApplicationRecord
   validates_presence_of :email, :password_digest
   validates :username, uniqueness: true
 
   #encrypt password
   has_secure_password

end
