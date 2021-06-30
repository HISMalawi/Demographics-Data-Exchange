class PushTracker < ApplicationRecord
  self.primary_key = :site_id,:push_type
end
