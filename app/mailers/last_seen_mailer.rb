# frozen_string_literal: true

# Class to send last seen notifications
class LastSeenMailer < ApplicationMailer
  after_action :log_mail

  def summary_of_last_seen(last_seen)
    @last_seen_data = last_seen
    @mailing_list = MailingList.pluck(:email)
    @admin_list = MailingList.joins(:roles)
                            .where(roles: { role: 'Admin' })
                            .pluck(:email)

    begin
      # Use the mailer's view context
      html = render_to_string(
        template: 'last_seen_mailer/last_seen_more_than_3_days',
        locals: { last_seen_data: @last_seen_data },
        layout: false
      )
      Rails.logger.debug "Rendered HTML: '#{html}'"

      filename = "last_seen_more_than_3_days_#{Date.today.strftime('%Y%m%d')}.html"
      attachments[filename] = {
        mime_type: 'text/html',
        content: html.force_encoding('UTF-8')
      }

      if @mailing_list.present? || @admin_list.present?
        mail(
          to: @mailing_list,
          cc: @admin_list,
          subject: 'Summary Of DDE Sites Not Reachable'
        ) 
      else
        Rails.logger.warn 'Email not sent: No recipients'
      end
    rescue StandardError => e
      Rails.logger.error "Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
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
