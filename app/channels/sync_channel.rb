class SyncChannel < ApplicationCable::Channel
  def subscribed
    stream_from "sync_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
