# frozen_string_literal: true

class LowNpidNotificationJob < ApplicationJob
  require 'mailer_service/low_npid_notification_service'
  queue_as :default

  def perform(*args)
    result = LowNpidNotificationService.processed_data
    LowNpidNotificationMailer.low_npid_summary(result).deliver_now
  end

end
