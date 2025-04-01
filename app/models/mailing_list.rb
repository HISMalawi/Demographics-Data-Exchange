class MailingList < ApplicationRecord
    has_many :mailer_locations, foreign_key: 'mailer_id'
    has_many :mailer_districts, foreign_key: 'mailer_id'
    belongs_to :roles, class_name: 'Role',  foreign_key: 'role_id'
end
