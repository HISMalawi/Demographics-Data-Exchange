# frozen_string_literal: true

# Class to send last seen notifications
class LastSeenMailer < ApplicationMailer
  after_action :log_mail

  def last_seen_more_than_3_days(district_data)
   
    @district_data = district_data
    @mailing_list = MailingList.joins(:mailer_districts).where(
                  'mailer_districts.district_id = ?', 
                  district_data[:district_id]).pluck(:email)
        
    if @mailing_list.blank?            
        @mailing_list = MailingList.joins(:roles).where('roles.role = ?', 'Admin').pluck(:email) 
        mail(to: @mailing_list,
          subject: "Please check  #{district_data[:name]} was last seen more than 3 days ago"
          ) 
    else
        mail(to: @mailing_list,
        #cc: MailingList.joins(:roles).where('roles.role = ?', 'Admin').pluck(:email),
        subject: "Please check #{district_data[:name]} was last seen more than 3 days ago"
        ) 
    end
  end

  private

  def mail_not_sent
    #MailingLog.where('location_id = ? AND notification_type = ?  
    #      AND created_at = ?', @site_details["location_id"],  
    #      "#{mail.to} #{mail.subject}", Date.today).blank?
  end

  def log_mail
     # MailingLog.create!(location_id: @site_details[:location_id],
      #                  notification_type: "#{mail.to} #{mail.subject}"
       #               )
     # Rails.logger.info("Email sent #{mail.to} - #{mail.subject}")
  end
end
