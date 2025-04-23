class LowNpidNotificationMailerPreview < ActionMailer::Preview
    require 'mailer_service/low_npid_notification_service'
    
    def low_npid_summary
      result = LowNpidNotificationService.processed_data
      
      if result[:districts].any?
          LowNpidNotificationMailer.low_npid_summary(result)
      else
          Mail.new(
            to: 'preview@example.com',
            from: 'no-reply@example.com',
            subject: 'Low NPID Notification Summary - No Data Available',
            body: 'There is no data available to render this preview.'
          )
      end
      
    end
end