class MailingList < ApplicationRecord
    validates :email, presence: true, uniqueness: { case_sensitive: false }
    validates :phone_number, presence: true, uniqueness: true
    has_many :mailer_locations, foreign_key: 'mailer_id'
    has_many :mailer_districts, foreign_key: 'mailer_id'
    belongs_to :roles, class_name: 'Role',  foreign_key: 'role_id'
end
