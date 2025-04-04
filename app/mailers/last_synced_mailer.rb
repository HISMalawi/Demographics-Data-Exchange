class LastSyncedMailer < ApplicationMailer
    after_action :log_mail

    def last_synced_more_than_3_days(grouped_districts)
      @district_data = grouped_districts
      @mailing_list = MailingList.pluck(:email)
      
      @admin_list = MailingList.joins(:roles).where('roles.role = ?', 'Admin').pluck(:email)
      
      if mail_not_sent
        mail(to: @mailing_list, cc: @admin_list, subject: "Summary of DDE Sites Not Syncing")
      end
    end

    private

    def mail_not_sent
      MailingLog.where(
        notification_type:  "#{mail.to} #{mail.subject}",
        created_at: Time.zone.today.beginning_of_day..Time.zone.today.end_of_day
      )
    end

    def log_mail
      return unless mail.perform_deliveries
      MailingLog.create!(
        notification_type: "#{mail.to} #{mail.subject}"
      )
    end
end
