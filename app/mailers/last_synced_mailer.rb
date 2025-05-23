class LastSyncedMailer < ApplicationMailer
    after_action :log_mail

    def summary_of_last_synced(last_synced)
      @last_synced_data = last_synced
      @mailing_list = MailingList.joins(:roles).where(roles: { role: 'HIS Officer' }).pluck(:email, :id)
      @cc_list = MailingList.joins(:roles).where(roles: { role: ['Admin', 'Zonal Coordinator', 'Systems Analyst Role', 'Help Desk Officer'] })
                               .pluck(:email, :id)

      @emails, @mailer_ids = @mailing_list.transpose unless @mailing_list.empty?
      @cc_emails, @cc_mailer_ids = @cc_list.transpose unless @cc_list.empty? 

      begin
     
        html = render_to_string(
          template: 'last_synced_mailer/last_synced_more_than_3_days',
          locals: { last_synced_data: @last_synced_data },
          layout: false
        )
        
        Rails.logger.debug "Rendered HTML: '#{html}'"
  
        filename = "last_synced_more_than_3_days_#{Date.today.strftime('%Y%m%d')}.html"
        file_path = Rails.root.join('public', 'reports', filename)
        FileUtils.mkdir_p(File.dirname(file_path))
        File.open(file_path, 'w') { |f| f.write(html.force_encoding('UTF-8'))}
        
        # Generate public URL
        host = Rails.application.routes.default_url_options[:host] || 'http://localhost:8050'

        @report_url = "#{host}/v1/reports/#{filename}"  # Used summary erb.html view  

        if @emails.present? || @cc_emails.present?
          mail(
            to: @emails,
            cc: @cc_emails,
            subject: 'Summary Of DDE Sites Syncing'
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
        notification_type:  "To:#{@mailer_ids} CC:#{@cc_mailer_ids} #{mail.subject}",
        created_at: Time.zone.today.beginning_of_day..Time.zone.today.end_of_day
      )
    end

    def log_mail
      return unless mail.perform_deliveries
      MailingLog.create!(
        notification_type: "To:#{@mailer_ids} CC:#{@cc_mailer_ids} #{mail.subject}"
      )
    end
end
