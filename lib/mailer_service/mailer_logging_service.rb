module MailerLoggingService
    def self.mail_not_sent
        MailingLog.where('location_id = ? AND notification_type = ? \
            AND data(created_at) = ?', npid_details[:location_id], \
            "#{mail.to} #{mail.subject}", Date.today).blank?
    end

    def self.log_mail
        MailingLog.create!(location_id: @site_details[:location_id],
                          notification_type: "#{mail.to} #{mail.subject}"
                        )
        Rails.logger.info("Email sent #{mail.to} - #{mail.subject}")
    end
end