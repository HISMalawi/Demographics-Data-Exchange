class MailerDistrict < ApplicationRecord
    belongs_to :district, class_name: 'District', foreign_key: 'district_id'
    belongs_to :mailing_list, class_name: 'MailingList', foreign_key: 'mailer_id'
end
