class LastSyncedMailer < ApplicationMailer
    after_action :log_mail

    def last_synced_more_than_3_days(site_details)
        @site_details = site_details
        @mailing_list = MailingList.joins(:mailer_locations).where(
            'mailer_locations.location_id = ?', 
            site_details["location_id"]).pluck(:email)
        
       
        if @mailing_list.blank?            
            @mailing_list = MailingList.joins(:roles).where('roles.role = ?', 'Admin').pluck(:email) 
            mail(to: @mailing_list,
             subject: "Please check #{site_details["site_name"]} last synced more than 3 days ago"
             ) 
        else
            mail(to: @mailing_list,
            #cc: MailingList.joins(:roles).where('roles.role = ?', 'Admin').pluck(:email),
            subject: "Please check #{site_details["site_name"]} last synced more than 3 days ago"
            ) 
        end
    end

    private

    def mail_not_sent
        MailingLog.where('location_id = ? AND notification_type = ?  
              AND created_at = ?', @site_details["location_id"],  
              "#{mail.to} #{mail.subject}", Date.today).blank?
    end

    def log_mail
        MailingLog.create!(location_id: @site_details[:location_id],
                          notification_type: "#{mail.to} #{mail.subject}"
                        )
        Rails.logger.info("Email sent #{mail.to} - #{mail.subject}")
    end
end
