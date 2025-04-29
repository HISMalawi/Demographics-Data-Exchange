class LowNpidNotificationMailer < ApplicationMailer
    after_action :log_mail

    def low_npid_summary(low_npid_data)
      @low_npid_data = low_npid_data
        
      @mailing_list = MailingList.joins(:roles).where(roles: { role: 'Admin' }).pluck(:email, :id)

      @emails, @mailer_ids = @mailing_list.transpose unless @mailing_list.empty?

      begin
        html = render_to_string(
          template: 'low_npid_notification_mailer/low_npid',
          locals: { low_npid_data: @low_npid_data },
          layout: false
        )
  
        Rails.logger.debug "Rendered HTML: '#{html}'"
    
        filename = "low_npid_#{Date.today.strftime('%Y%m%d')}.html"
        file_path = Rails.root.join('public', 'reports', filename)
        FileUtils.mkdir_p(File.dirname(file_path))
        File.open(file_path, 'w') { |f| f.write(html.force_encoding('UTF-8')) }
    
        # Generate public URL
        host = Rails.application.routes.default_url_options[:host] || 'http://localhost:8050'
  
        @report_url = "#{host}/v1/reports/#{filename}"  # Used summary erb.html view
    
        if @emails.present? 
          mail(
            to: @emails,
            subject: 'Summary Of DDE Sites With Low NPIDs'
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
        notification_type:  "#{@mailer_ids} #{mail.subject}",
        created_at: Time.zone.today.beginning_of_day..Time.zone.today.end_of_day )
    end
  
    def log_mail
      return unless mail.perform_deliveries
  
      MailingLog.create!(
        notification_type: "#{@mailer_ids} #{mail.subject}"
      )
    end
end
