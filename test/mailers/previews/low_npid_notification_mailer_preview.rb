class LowNpidNotificationMailerPreview < ActionMailer::Preview
    require 'mailer_service/low_npid_notification_service'
    
    def low_npid_summary
      result = LowNpidNotificationService.processed_data
      LowNpidNotificationMailer.low_npid_summary(result).deliver_now
    end
end