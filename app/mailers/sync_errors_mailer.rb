class SyncErrorsMailer < ApplicationMailer
  after_action :log_mail


  def summary_of_sync_errors(sync_error_data)
    @mailing_list = MailingList.joins(:roles).where(roles: { role: 'Admin' }).pluck(:email, :id)
    @emails, @mailer_ids = @mailing_list.transpose unless @mailing_list.empty?

    @sync_error_data = sync_error_data

    begin 
        html = render_to_string(
            template: 'sync_errors_mailer/sync_errors',
            locals: {  sync_error_data: @last_synced_data },
            layout: false
        )
        
        Rails.logger.debug "Rendered HTML: '#{html}'"

        filename = "sync_errors_#{Date.today.strftime('%Y%m%d')}.html"
        file_path = Rails.root.join('public', 'reports', filename)
        FileUtils.mkdir_p(File.dirname(file_path))
        File.open(file_path, 'w') { |f| f.write(html.force_encoding('UTF-8'))}

        # Generate public URL
        host = Rails.application.routes.default_url_options[:host] || 'http://localhost:8050'

        @report_url = "#{host}/v1/reports/#{filename}" # Used summary erb.html

        if @emails.present?
        mail(
            to: @emails,
            subject: 'Summary Of DDE Sync Errors'
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

  def log_mail
    return unless mail.perform_deliveries

    MailingLog.create!(
        notification_type: "sync_errors #{mail.subject}",
    )   
  end

end
