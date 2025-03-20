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
    end

    if mail_not_sent
      mail(to: @mailing_list, subject: "Please check #{district_data[:name]} last seen more than 3 days ago")
    end
  end

  private

  def mail_not_sent
    MailingLog.where(
      district_id: @district_data[:district_id],
      notification_type:  "#{mail.to} #{mail.subject}",
      created_at: Time.zone.today.beginning_of_day..Time.zone.today.end_of_day
    )
  end

  def log_mail
    return unless mail.perform_deliveries
 
     MailingLog.create!(
      district_id: @district_data[:district_id],
      notification_type: "#{mail.to} #{mail.subject}"
     )
  end
end
