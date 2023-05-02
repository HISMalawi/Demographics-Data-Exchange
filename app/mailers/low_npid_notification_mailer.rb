class LowNpidNotificationMailer < ApplicationMailer
    after_action :log_mail

    def low_npid(npid_details)
        @site_details = npid_details
        @mailing_list = MailingList.joins(:mailer_locations).where(
            'mailer_locations.location_id = ?', 
            npid_details[:location_id]).pluck(:email)
        
        if @mailing_list.blank?            
            @mailing_list = MailingList.joins(:roles).where('roles.role = ?', 'Admin').pluck(:email) 
            mail(to: @mailing_list,
             subject: "Low NPIDs at #{npid_details[:location_name]}") if \
             mail_not_sent
        else
            mail(to: @mailing_list,
            cc: MailingList.joins(:roles).where('roles.role = ?', 'Admin').pluck(:email),
            subject: "Low NPIDs at #{npid_details[:location_name]}") if \
            mail_not_sent
        end
    end

    private

    def mail_not_sent
        MailingLog.where('location_id = ? AND notification_type = ? \
            AND data(created_at) = ?', npid_details[:location_id], \
            "#{mail.to} #{mail.subject}", Date.today).blank?
    end

    def log_mail
        MailingLog.create!(location_id: @site_details[:location_id],
                          notification_type: "#{mail.to} #{mail.subject}"
                        )
        Rails.logger.info("Email sent #{mail.to} - #{mail.subject}")
    end
end
