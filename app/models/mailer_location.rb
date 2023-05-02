class MailerLocation < ApplicationRecord
    belongs_to :locations, class_name: 'Location', foreign_key: 'location_id'
    belongs_to :mailing_lists, class_name: 'MailingList', foreign_key: 'mailer_id'
end
